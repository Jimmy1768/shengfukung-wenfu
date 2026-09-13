require "test_helper"
require "open3"
require "tmpdir"

# bin/staging runs a Rails command against a checkout's deployment environment
# by sourcing the shared environment file and then that checkout's instance.env.
#
# Two behaviours are pinned here. Refusing when a file is unreadable, because a
# wrapper that sourced whichever file happened to exist would run with half an
# environment, which is how a command ends up on the wrong database. And
# exporting exactly one thing -- a declaration of which environment it believes
# it is, never a copy of any value. Copying a value would protect the console
# and leave the systemd service reading the instance file, with nothing able to
# say which was right when they disagreed.
class StagingWrapperTest < ActiveSupport::TestCase
  REPO_ROOT = Rails.root.join("..").expand_path
  WRAPPER = REPO_ROOT.join("bin/staging").to_s

  # The five values that differ per deployment. The wrapper must carry none of
  # them; they live in instance.env and nowhere else.
  PARTITION_KEYS = %w[RAILS_ENV RACK_ENV PUMA_PORT PGDATABASE S3_OBJECT_PREFIX].freeze

  test "the wrapper exists and is executable" do
    assert File.executable?(WRAPPER), "bin/staging must be executable"
  end

  test "with no arguments it prints usage and refuses" do
    stdout, _stderr, status = run_wrapper

    assert_equal 1, status.exitstatus
    assert_match "Usage: bin/staging", stdout
  end

  test "it refuses when the shared environment file is unreadable, and names it" do
    _stdout, stderr, status = run_wrapper("rails", "runner", "puts 1")

    assert_equal 1, status.exitstatus
    assert_match "cannot read the shared environment file", stderr
    assert_match "/nonexistent/shared.env", stderr
  end

  test "it refuses when only the instance file is missing, and says how to make one" do
    with_env_file("SECRET_KEY_BASE=x\n") do |shared|
      _stdout, stderr, status = run_wrapper("rails", "runner", "puts 1", shared: shared)

      assert_equal 1, status.exitstatus
      assert_match "cannot read the instance environment file", stderr
      assert_match "/nonexistent/instance.env", stderr
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

  # --- criterion 4 ---------------------------------------------------------

  test "it declares the environment it believes it is running" do
    with_env_file("") do |shared|
      with_env_file("") do |instance|
        stdout, _stderr, status = run_wrapper(
          "ruby", "-e", 'print ENV["WENFU_DECLARED_ENVIRONMENT"].inspect',
          shared: shared, instance: instance
        )

        assert_predicate status, :success?
        assert_equal '"staging"', stdout.strip
      end
    end
  end

  # A value the wrapper set itself would silently win over the instance file.
  # This proves the five partition values arrive from the file untouched.
  test "it does not overwrite any value the instance file provides" do
    supplied = PARTITION_KEYS.map { |key| "#{key}=sentinel_#{key.downcase}\n" }.join

    with_env_file("") do |shared|
      with_env_file(supplied) do |instance|
        script = PARTITION_KEYS.map { |key| %(ENV["#{key}"]) }.join(%(+","+))
        stdout, _stderr, status = run_wrapper(
          "ruby", "-e", "print #{script}", shared: shared, instance: instance
        )

        assert_predicate status, :success?
        assert_equal PARTITION_KEYS.map { |key| "sentinel_#{key.downcase}" }.join(","),
          stdout.strip
      end
    end
  end

  # The behavioural tests above pass if the wrapper exports a partition value
  # that happens to equal what the instance file said. This one does not: it
  # fails the moment a second export appears, whatever its value.
  test "the wrapper contains exactly one export, and it is the declaration" do
    exports = File.readlines(WRAPPER).grep(/^\s*export\s/).map(&:strip)

    assert_equal ['export WENFU_DECLARED_ENVIRONMENT="staging"'], exports,
      "bin/staging must export its declaration and nothing else. A copied value " \
      "here becomes a second source of truth that only the console reads, while " \
      "the systemd service keeps reading instance.env."
  end

  test "the wrapper names no partition value at all" do
    source = File.read(WRAPPER)
    body = source.lines.reject { |line| line.strip.start_with?("#") }.join

    PARTITION_KEYS.each do |key|
      assert_no_match(/^\s*(export\s+)?#{key}=/, body,
        "#{key} is a partition value and belongs in instance.env, not in the wrapper")
    end
  end

  # --- the override may not come from a file ------------------------------

  # WENFU_EXPECTED_DATABASE acknowledges a one-off exception on one invocation;
  # the guard still demands an exact match. In a file it stops being one-off and
  # silently disarms every later boot, which is how a convention like this rots:
  # someone adds it to an env file to stop the WARN line.
  test "it refuses when the override is set in the shared file, naming file and key" do
    with_env_file("SECRET_KEY_BASE=x\nWENFU_EXPECTED_DATABASE=templemate_data\n") do |shared|
      with_env_file("RAILS_ENV=staging\n") do |instance|
        _stdout, stderr, status = run_wrapper(
          "ruby", "-e", "print 1", shared: shared, instance: instance
        )

        assert_equal 1, status.exitstatus
        assert_match "WENFU_EXPECTED_DATABASE is set in the shared environment file", stderr
        assert_match shared, stderr
      end
    end
  end

  test "it refuses when the override is exported from the instance file" do
    with_env_file("SECRET_KEY_BASE=x\n") do |shared|
      with_env_file("export WENFU_EXPECTED_DATABASE=templemate_data\n") do |instance|
        _stdout, stderr, status = run_wrapper(
          "ruby", "-e", "print 1", shared: shared, instance: instance
        )

        assert_equal 1, status.exitstatus
        assert_match "WENFU_EXPECTED_DATABASE is set in the instance environment file", stderr
        assert_match instance, stderr
      end
    end
  end

  # A refusal that fired on a commented line would teach people to delete the
  # comment explaining why the line is not there.
  test "a commented-out override is not a refusal" do
    with_env_file("SECRET_KEY_BASE=x\n") do |shared|
      with_env_file("# WENFU_EXPECTED_DATABASE=templemate_data\n") do |instance|
        stdout, _stderr, status = run_wrapper(
          "ruby", "-e", 'print "RAN"', shared: shared, instance: instance
        )

        assert_predicate status, :success?
        assert_equal "RAN", stdout.strip
      end
    end
  end

  # The supported way to use it. This is what the refusal is steering people to,
  # so it has to keep working.
  test "the override set inline is allowed and reaches the process" do
    with_env_file("SECRET_KEY_BASE=x\n") do |shared|
      with_env_file("RAILS_ENV=staging\n") do |instance|
        stdout, _stderr, status = run_wrapper(
          "ruby", "-e", 'print ENV["WENFU_EXPECTED_DATABASE"]',
          shared: shared, instance: instance,
          env: { "WENFU_EXPECTED_DATABASE" => "templemate_data_staging" }
        )

        assert_predicate status, :success?
        assert_equal "templemate_data_staging", stdout.strip
      end
    end
  end

  private

  def run_wrapper(*args, shared: "/nonexistent/shared.env",
                  instance: "/nonexistent/instance.env", env: {})
    Open3.capture3(
      { "WENFU_SHARED_ENV_FILE" => shared, "WENFU_INSTANCE_ENV_FILE" => instance }.merge(env),
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
