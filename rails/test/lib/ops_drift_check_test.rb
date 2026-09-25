require "test_helper"
require "open3"
require "tmpdir"
require "fileutils"

# bin/check_ops_drift reports whether the committed ops artefacts match the
# copies installed on a host.
#
# Every case runs the real script against fixture directories, never against
# /etc. The script takes its two installed locations from the environment for
# exactly this reason: a check that could only be exercised on the droplet would
# be a check nobody exercised.
class OpsDriftCheckTest < ActiveSupport::TestCase
  REPO_ROOT = Rails.root.join("..").expand_path
  SCRIPT = REPO_ROOT.join("bin/check_ops_drift").to_s
  SYSTEMD_SOURCE = REPO_ROOT.join("ops/systemd")
  NGINX_SOURCE = REPO_ROOT.join("ops/nginx")

  # --- criterion 3: it looks and cannot learn to touch --------------------

  # The same shape as the drop-scanner in test_database_provisioner_test.rb.
  # Fixing drift is a deploy: a different act, with a different approval. A
  # script that reported drift and could also repair it would be one edit away
  # from repairing it automatically.
  WRITE_VERBS = {
    "cp" => /^[^#]*\bcp\s/,
    "mv" => /^[^#]*\bmv\s/,
    "rm" => /^[^#]*\brm\s/,
    "install" => /^[^#]*\binstall\s+-/,
    "tee" => /^[^#]*\btee\s/,
    "systemctl" => /^[^#]*\bsystemctl\s/,
    "nginx -s" => /^[^#]*\bnginx\s+-/,
    "chmod" => /^[^#]*\bchmod\s/,
    "chown" => /^[^#]*\bchown\s/,
    "ln" => /^[^#]*\bln\s+-/,
    "mkdir" => /^[^#]*\bmkdir\s/,
    "touch" => /^[^#]*\btouch\s/,
    "sed -i" => /^[^#]*\bsed\s+-i/,
    "dd" => /^[^#]*\bdd\s/,
    "truncate" => /^[^#]*\btruncate\s/,
    "append redirect" => /^[^#]*>>/,
    # /dev/null is discarding output, not writing a file.
    "redirect to an absolute path" => %r{^[^#]*>\s*"?/(?!dev/null)}
  }.freeze

  test "the script contains no verb that could write anything" do
    source = File.read(SCRIPT)

    offenders = WRITE_VERBS.select { |_name, pattern| source.match?(pattern) }.keys

    assert_empty offenders,
      "bin/check_ops_drift must only look. It found #{offenders.join(', ')}. Repairing " \
      "drift is a deploy, which is a different act with a different approval, and a " \
      "reporting script that can also repair is one edit from repairing silently."
  end

  # The env file is not a copy of the template -- the template holds placeholders
  # and the installed file holds real values -- so comparing content there means
  # nothing, and that file holds live secrets.
  test "the script says why the shared env file is out of scope" do
    source = File.read(SCRIPT)

    assert_match(/OUT OF SCOPE/, source)
    assert_match(%r{/etc/default/shengfukung-demo-env}, source,
      "the exclusion has to name the file, or the next person adds it back")
  end

  test "the script never reads the shared env file" do
    body = File.read(SCRIPT).lines.reject { |line| line.strip.start_with?("#") }.join

    assert_no_match(%r{/etc/default}, body,
      "the shared env file holds live secrets and must not be read, only mentioned in the note")
  end

  # --- criteria 1 and 2: three states, and an exit code to gate on --------

  # Success means every artefact matched, not merely that the ones present did.
  test "a host with every artefact installed and identical reports no drift and succeeds" do
    with_everything_installed do |dirs|
      stdout, _stderr, status = run_check(dirs)

      assert_predicate status, :success?, "everything matched, so the check must succeed"
      assert_match(/^matched\s+shengfukung-demo-puma\.service/, stdout)
      assert_match(/0 differing, 0 missing/, stdout)
      assert_match(/no drift/, stdout)
    end
  end

  # One artefact drifting is enough to fail the whole run, however many matched.
  test "one differing artefact among many matched still fails the run" do
    with_everything_installed(drift: "shengfukung-demo-staging-puma.service") do |dirs|
      stdout, _stderr, status = run_check(dirs)

      assert_not status.success?,
        "a run where one artefact drifted reported success; the exit code is the only " \
        "part of this a deploy script can gate on"
      assert_match(/^differing\s+shengfukung-demo-staging-puma/, stdout)
      assert_match(/1 differing/, stdout)
    end
  end

  test "a differing copy is reported differing, with a count and both paths" do
    with_fixture(differing: %w[shengfukung-demo-staging-puma.service]) do |dirs|
      stdout, _stderr, status = run_check(dirs)

      assert_not status.success?, "a difference reported as success is a report nobody can gate on"
      assert_match(/^differing\s+shengfukung-demo-staging-puma\.service \(\d+ differing lines\)/, stdout)
      assert_match(/committed: .*ops\/systemd/, stdout, "criterion 4 needs the path of each side")
      assert_match(/installed: /, stdout)
    end
  end

  # A file with no installed counterpart was never deployed at all. That is a
  # different fact from one that was deployed and has since drifted, and it
  # points at a different fix.
  test "an absent copy is reported missing, not as a difference" do
    with_fixture(missing: %w[shengfukung-demo-sidekiq.service]) do |dirs|
      stdout, _stderr, status = run_check(dirs)

      assert_not status.success?
      assert_match(/^missing\s+shengfukung-demo-sidekiq\.service/, stdout,
        "an artefact with no installed copy was not reported missing. If it was reported " \
        "differing instead, the missing case has collapsed into the differing case: a file " \
        "that was never installed now reads as one that was installed and then changed, " \
        "and those point at different fixes.")
      assert_no_match(/^differing\s+shengfukung-demo-sidekiq\.service/, stdout,
        "missing collapsed into differing: a file that was never installed would be " \
        "read as one that was installed and then changed")
    end
  end

  test "the three states are distinguished in one run" do
    with_fixture(
      matched: %w[shengfukung-demo-puma.service],
      differing: %w[shengfukung-demo-staging-puma.service],
      missing: %w[shengfukung-demo-sidekiq.service]
    ) do |dirs|
      stdout, _stderr, status = run_check(dirs)

      assert_not status.success?
      assert_match(/^matched\s+shengfukung-demo-puma/, stdout)
      assert_match(/^differing\s+shengfukung-demo-staging-puma/, stdout)
      assert_match(/^missing\s+shengfukung-demo-sidekiq/, stdout)
      assert_match(/1 matched, 1 differing, \d+ missing/, stdout)
    end
  end

  # --- criterion 5: where it ran ------------------------------------------

  # Both checkouts on the host hold the same ops/ at different commits, so a
  # report that does not say where it ran cannot be acted on.
  test "it says which checkout it is standing in" do
    with_fixture(matched: %w[shengfukung-demo-puma.service]) do |dirs|
      stdout, _stderr, _status = run_check(dirs)

      assert_match(REPO_ROOT.to_s, stdout, "the report must name the checkout it ran from")
      assert_match(/checkout: .* \(\h{7,} on .+\)/, stdout, "and the commit it sat at")
    end
  end

  # --- criterion 6: harmless, and never falsely green, off the droplet ----

  test "off the droplet everything is missing and the run fails" do
    Dir.mktmpdir do |empty|
      stdout, _stderr, status = run_check(
        { systemd: File.join(empty, "nope"), nginx: File.join(empty, "also-nope") }
      )

      assert_not status.success?, "nothing to compare must never report success"
      assert_match(/^missing/, stdout)
      assert_no_match(/^matched/, stdout, "a false match off the droplet is the worst outcome")
      assert_match(/0 matched/, stdout)
    end
  end

  # Pointed at a tree with no artefacts at all, the honest answer is that
  # nothing was checked -- not that nothing was wrong.
  test "a checkout with no ops artefacts fails rather than reporting no drift" do
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "bin"))
      FileUtils.mkdir_p(File.join(root, "ops/systemd"))
      FileUtils.mkdir_p(File.join(root, "ops/nginx"))
      FileUtils.cp(SCRIPT, File.join(root, "bin/check_ops_drift"))

      stdout, _stderr, status = Open3.capture3(
        { "OPS_DRIFT_SYSTEMD_DIR" => File.join(root, "systemd"),
          "OPS_DRIFT_NGINX_DIR" => File.join(root, "nginx") },
        File.join(root, "bin/check_ops_drift")
      )

      assert_not status.success?
      assert_match(/nothing was checked/, stdout)
      assert_no_match(/no drift/, stdout)
    end
  end

  private

  # Installs every committed artefact, optionally corrupting one of them.
  def with_everything_installed(drift: nil)
    Dir.mktmpdir do |dir|
      systemd = File.join(dir, "systemd")
      nginx = File.join(dir, "nginx")
      FileUtils.mkdir_p(systemd)
      FileUtils.mkdir_p(nginx)

      Dir.glob(SYSTEMD_SOURCE.join("*.service")).each { |p| FileUtils.cp(p, systemd) }
      Dir.glob(NGINX_SOURCE.join("*.conf")).each { |p| FileUtils.cp(p, nginx) }

      if drift
        path = File.join(systemd, drift)
        File.write(path, File.read(path).sub(" S3_OBJECT_PREFIX=staging", ""))
      end

      yield({ systemd: systemd, nginx: nginx })
    end
  end

  def run_check(dirs, only: false)
    Open3.capture3(
      { "OPS_DRIFT_SYSTEMD_DIR" => dirs[:systemd].to_s, "OPS_DRIFT_NGINX_DIR" => dirs[:nginx].to_s },
      SCRIPT, chdir: REPO_ROOT.to_s
    )
  end

  # Builds an installed-side fixture. Anything not named is simply absent, which
  # is how the missing cases arise.
  def with_fixture(matched: [], differing: [], missing: [], confs: [])
    Dir.mktmpdir do |dir|
      systemd = File.join(dir, "systemd")
      nginx = File.join(dir, "nginx")
      FileUtils.mkdir_p(systemd)
      FileUtils.mkdir_p(nginx)

      matched.each { |name| FileUtils.cp(SYSTEMD_SOURCE.join(name), File.join(systemd, name)) }
      confs.each { |name| FileUtils.cp(NGINX_SOURCE.join(name), File.join(nginx, name)) }

      # Reproduces the drift actually observed on taiwan-01-web on 2026-09-14:
      # the staging unit installed without S3_OBJECT_PREFIX=staging, so staging
      # inherited production's prefix and wrote into its S3 namespace.
      differing.each do |name|
        content = File.read(SYSTEMD_SOURCE.join(name)).sub(" S3_OBJECT_PREFIX=staging", "")
        File.write(File.join(systemd, name), content)
      end

      missing.each { |name| assert_not File.exist?(File.join(systemd, name)) }

      yield({ systemd: systemd, nginx: nginx })
    end
  end
end
