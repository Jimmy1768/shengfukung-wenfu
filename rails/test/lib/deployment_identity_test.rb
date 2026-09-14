require "test_helper"
require "stringio"

# The guard that keeps a process on the database its environment is supposed to
# use. Shape settled in §4a of ENV_PARTITION_BY_MUTABILITY_PLAN.md.
#
# The decision table under test, in one place:
#
#   declared, disagrees            -> refuse, TTY or not
#   not declared, disagrees, TTY   -> warn
#   not declared, disagrees, no TTY-> refuse
#   override set                   -> expect exactly that name, both paths
#
# These drive DeploymentIdentity directly rather than by booting an environment,
# which is why the decision was extracted out of the initializer at all. The
# initializer's own wiring is asserted at the bottom.
class DeploymentIdentityTest < ActiveSupport::TestCase
  # Minimal stand-in; Rails.logger is not available to a plain object under test.
  class FakeLogger
    attr_reader :warnings

    def initialize = @warnings = []
    def warn(message) = @warnings << message
  end

  def guard(**overrides)
    DeploymentIdentity.new(**{ env: "staging", database: "templemate_data_staging" }.merge(overrides))
  end

  # --- agreement -----------------------------------------------------------

  test "production on its own database passes" do
    assert guard(env: "production", database: "templemate_data").verify!
  end

  test "staging on its own database passes" do
    assert guard.verify!
  end

  test "a declaration that agrees with the resolved database passes" do
    assert guard(declared_environment: "staging").verify!
  end

  # --- criterion 1: a declared mismatch refuses, present or not ------------

  # The defect this whole round exists for: a wrapper named `staging` used to
  # warn and open a production console anyway.
  test "a declared environment disagreeing with the database refuses away from a console" do
    error = assert_raises(DeploymentIdentity::Mismatch) do
      guard(declared_environment: "staging", database: "templemate_data", tty: false).verify!
    end

    assert_match "templemate_data_staging", error.message
    assert_match "WENFU_DECLARED_ENVIRONMENT=staging", error.message
  end

  # The same, with a human watching. Presence is what makes a warning readable;
  # it is not what makes it timely. A broken promise is refused either way.
  test "a declared environment disagreeing with the database refuses at a console too" do
    assert_raises(DeploymentIdentity::Mismatch) do
      guard(declared_environment: "staging", database: "templemate_data", tty: true).verify!
    end
  end

  test "a declaration naming an environment with no known database refuses" do
    error = assert_raises(DeploymentIdentity::Mismatch) do
      guard(env: "development", declared_environment: "banana",
            database: "anything", tty: true).verify!
    end

    assert_match "banana", error.message
    assert_match "no known environment", error.message
  end

  # --- criterion 2: two positive conditions for the permissive path --------

  test "no declaration plus a TTY warns instead of raising" do
    warner = StringIO.new
    subject = guard(database: "templemate_data", tty: true)

    assert_nothing_raised { assert_not subject.verify!(warner: warner) }
    assert_match "MISMATCH", warner.string
    assert_match "templemate_data_staging", warner.string
  end

  # Absence alone must not be permissive: a declaration can go missing from the
  # wrapper failing before its export, `sudo` or `env -i` stripping it, or a
  # refactor moving the export below the exec.
  test "no declaration without a TTY refuses" do
    assert_raises(DeploymentIdentity::Mismatch) do
      guard(database: "templemate_data", tty: false).verify!
    end
  end

  test "a warning is silent when the database agrees" do
    warner = StringIO.new

    assert guard(tty: true).verify!(warner: warner)
    assert_empty warner.string
  end

  # --- criterion 3: the override is an acknowledgement, not a bypass -------

  test "the override passes only on an exact match" do
    assert guard(env: "production", database: "templemate_restored",
                 override: "templemate_restored").verify!
  end

  test "the override refuses when the resolved name differs from it" do
    error = assert_raises(DeploymentIdentity::Mismatch) do
      guard(env: "production", database: "templemate_data",
            override: "templemate_restored", tty: false).verify!
    end

    assert_match "templemate_restored", error.message
    assert_match "WENFU_EXPECTED_DATABASE", error.message
  end

  # It cannot be used to skip the comparison, only to state a different answer
  # and be held to it. A near miss is still a refusal.
  test "the override does not let a mismatched database through on a declared path" do
    assert_raises(DeploymentIdentity::Mismatch) do
      guard(declared_environment: "staging", database: "templemate_data",
            override: "templemate_data_staging", tty: true).verify!
    end
  end

  test "the override logs at WARN whenever it is active" do
    logger = FakeLogger.new

    guard(env: "production", database: "templemate_restored",
          override: "templemate_restored").verify!(logger: logger)

    assert_equal 1, logger.warnings.length
    assert_match "WENFU_EXPECTED_DATABASE=templemate_restored", logger.warnings.first
  end

  test "no override means no WARN line" do
    logger = FakeLogger.new

    guard.verify!(logger: logger)

    assert_empty logger.warnings
  end

  # --- unguarded environments ---------------------------------------------

  test "development with nothing declared is not guarded" do
    subject = guard(env: "development", database: "anything_at_all", tty: false)

    assert_not subject.guarded?
    assert subject.verify!
  end

  test "test with nothing declared is not guarded" do
    assert guard(env: "test", database: "templemate_data", tty: false).verify!
  end

  # A declaration makes any environment guarded. Otherwise the wrapper could be
  # run in a development checkout and the claim would go unchecked.
  test "a declaration makes an otherwise unguarded environment guarded" do
    subject = guard(env: "development", declared_environment: "staging",
                    database: "templemate_dev", tty: true)

    assert subject.guarded?
    assert_raises(DeploymentIdentity::Mismatch) { subject.verify! }
  end

  test "a blank database is refused and named readably" do
    error = assert_raises(DeploymentIdentity::Mismatch) do
      guard(declared_environment: "staging", database: "").verify!
    end

    assert_match "(blank)", error.message
  end

  # --- constants -----------------------------------------------------------

  test "the expected databases are exactly production and staging" do
    assert_equal(
      { "production" => "templemate_data", "staging" => "templemate_data_staging" },
      DeploymentIdentity::EXPECTED_DATABASES
    )
  end

  test "the declaration and override variables are named as the wrapper expects" do
    assert_equal "WENFU_DECLARED_ENVIRONMENT", DeploymentIdentity::DECLARATION_VARIABLE
    assert_equal "WENFU_EXPECTED_DATABASE", DeploymentIdentity::OVERRIDE_VARIABLE
  end

  # --- wiring --------------------------------------------------------------

  # The class above is inert unless something calls it at boot. This fails if
  # the initializer is deleted or stops passing an input -- the failure mode
  # where every test above still passes and no process is actually guarded.
  test "the boot initializer exists and passes every input to the guard" do
    initializer = Rails.root.join("config/initializers/deployment_identity.rb")

    assert initializer.exist?,
      "config/initializers/deployment_identity.rb is gone; nothing invokes the guard at boot"

    source = initializer.read
    assert_match(/after_initialize/, source,
      "the guard must run in after_initialize; DeploymentIdentity is autoloaded and " \
      "cannot be referenced during initialization")
    assert_match(/DeploymentIdentity\.new/, source)
    assert_match(/verify!/, source)
    assert_match(/declared_environment:\s*ENV\[DeploymentIdentity::DECLARATION_VARIABLE\]/, source,
      "the declaration must be read from the environment, or every path looks undeclared")
    assert_match(/override:\s*ENV\[DeploymentIdentity::OVERRIDE_VARIABLE\]/, source)
    assert_match(/tty:\s*\$stdin\.tty\?/, source,
      "the TTY probe must be real; hardcoding it opens the permissive path")
    assert_match(/logger:/, source, "the override's WARN line needs a logger")
  end

  test "database.yml names the database for production and staging" do
    source = Rails.root.join("config/database.yml").read
    guarded = source[/^production:.*/m]

    assert_match(/database: <%= ENV\.fetch\("PGDATABASE", nil\) %>/, guarded)
    assert_no_match(/^\s+url:/, guarded,
      "a url: key here resolves to nil without DATABASE_URL and defeats the guard")
  end
end
