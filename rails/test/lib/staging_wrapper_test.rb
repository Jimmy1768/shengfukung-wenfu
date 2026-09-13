require "test_helper"
require "open3"
require "tmpdir"

# bin/staging runs a Rails command against a checkout's deployment environment
# by sourcing the shared environment file and then that checkout's instance.env.
#
# Refusing is the behaviour under test. On a development machine neither file
# exists, so refusing clearly is this script's normal local outcome, and the
# thing most worth pinning: a wrapper that sourced whichever file happened to
# exist would run commands with half an environment, which is how a command
# ends up on the wrong database.
class StagingWrapperTest < ActiveSupport::TestCase
  REPO_ROOT = Rails.root.join("..").expand_path
  WRAPPER = REPO_ROOT.join("bin/staging").to_s

  test "the wrapper exists and is executable" do
    assert File.executable?(WRAPPER), "bin/staging must be executable"
  end

  test "with no arguments it prints usage and refuses" do
    stdout, _stderr, status = run_wrapper

    assert_equal 1, status.exitstatus
    assert_match "Usage: bin/staging", stdout
  end

  test "it refuses when the shared environment file is unreadable, and names it" do
    _stdout, stderr, status = run_wrapper(
      "rails", "runner", "puts 1",
      shared: "/nonexistent/shared.env", instance: "/nonexistent/instance.env"
    )

    assert_equal 1, status.exitstatus
    assert_match "cannot read the shared environment file", stderr
    assert_match "/nonexistent/shared.env", stderr
  end

  test "it refuses when only the instance file is missing, and says how to make one" do
    with_env_file("SECRET_KEY_BASE=x\n") do |shared|
      _stdout, stderr, status = run_wrapper(
        "rails", "runner", "puts 1",
        shared: shared, instance: "/nonexistent/instance.env"
      )

      assert_equal 1, status.exitstatus
      assert_match "cannot read the instance environment file", stderr
      assert_match "/nonexistent/instance.env", stderr
      # The remedy has to be actionable, not just a complaint.
      assert_match "ops/env/template.instance.staging.env", stderr
    end
  end

  # The instance file is sourced second, so where the two ever set the same key
  # the instance wins. Under the partition they never do; this pins the order so
  # that stays true by construction rather than by luck.
  test "it sources the shared file first and the instance file second" do
    with_env_file("WENFU_TEST_MARKER=from_shared\nWENFU_TEST_ORDER=shared\n") do |shared|
      with_env_file("WENFU_TEST_ORDER=instance\n") do |instance|
        stdout, _stderr, status = run_wrapper(
          "ruby", "-e", 'print "#{ENV["WENFU_TEST_MARKER"]},#{ENV["WENFU_TEST_ORDER"]}"',
          shared: shared, instance: instance
        )

        assert_predicate status, :success?
        assert_equal "from_shared,instance", stdout.strip
      end
    end
  end

  private

  def run_wrapper(*args, shared: "/nonexistent/shared.env", instance: "/nonexistent/instance.env")
    Open3.capture3(
      { "WENFU_SHARED_ENV_FILE" => shared, "WENFU_INSTANCE_ENV_FILE" => instance },
      WRAPPER, *args, chdir: REPO_ROOT.to_s
    )
  end

  def with_env_file(contents)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "env")
      File.write(path, contents)
      yield path
    end
  end
end
