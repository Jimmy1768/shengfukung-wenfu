require "test_helper"
require "stringio"

# The guard that keeps production and staging on their own databases.
#
# These drive DeploymentIdentity directly rather than by booting an
# environment, which is the reason the decision was extracted out of
# config/initializers/deployment_identity.rb in the first place. The
# initializer's own wiring is asserted at the bottom.
class DeploymentIdentityTest < ActiveSupport::TestCase
  test "production on its own database passes" do
    guard = DeploymentIdentity.new(env: "production", database: "templemate_data")

    assert guard.ok?
    assert guard.verify!
  end

  test "staging on its own database passes" do
    guard = DeploymentIdentity.new(env: "staging", database: "templemate_data_staging")

    assert guard.ok?
    assert guard.verify!
  end

  # The incident this exists for: staging loses its PGDATABASE override and
  # inherits production's, so it would serve production's data silently.
  test "staging pointed at production's database is refused" do
    guard = DeploymentIdentity.new(env: "staging", database: "templemate_data")

    assert_not guard.ok?
    error = assert_raises(DeploymentIdentity::Mismatch) { guard.verify! }
    assert_match "templemate_data_staging", error.message
    assert_match "templemate_data", error.message
  end

  test "production pointed at staging's database is refused" do
    guard = DeploymentIdentity.new(env: "production", database: "templemate_data_staging")

    assert_not guard.ok?
    assert_raises(DeploymentIdentity::Mismatch) { guard.verify! }
  end

  # PGDATABASE present but empty is a typo, not a state anyone chooses, and it
  # is the one blank worth catching: libpq would fall back to the OS user's
  # database name rather than failing.
  test "a blank database is refused and says so readably" do
    guard = DeploymentIdentity.new(env: "production", database: "")

    error = assert_raises(DeploymentIdentity::Mismatch) { guard.verify! }
    assert_match "(blank)", error.message
  end

  test "development has no expectation and is never guarded" do
    guard = DeploymentIdentity.new(env: "development", database: "anything_at_all")

    assert_not guard.guarded?
    assert guard.ok?
    assert guard.verify!
  end

  test "test has no expectation and is never guarded" do
    guard = DeploymentIdentity.new(env: "test", database: "templemate_data")

    assert_not guard.guarded?
    assert guard.verify!
  end

  # Deliberate exclusion. A console is how you diagnose this misconfiguration,
  # and a guard that removes that tool is one that gets deleted rather than
  # fixed. It warns loudly instead, naming both databases.
  test "a console warns instead of raising, and names both databases" do
    guard = DeploymentIdentity.new(
      env: "staging", database: "templemate_data", console: true
    )
    warner = StringIO.new

    assert_nothing_raised { assert_not guard.verify!(warner: warner) }

    assert_match "MISMATCH", warner.string
    assert_match "templemate_data_staging", warner.string
    assert_match "templemate_data", warner.string
  end

  test "a console on the right database says nothing" do
    guard = DeploymentIdentity.new(
      env: "staging", database: "templemate_data_staging", console: true
    )
    warner = StringIO.new

    assert guard.verify!(warner: warner)
    assert_empty warner.string
  end

  test "the expected databases are exactly production and staging" do
    assert_equal(
      { "production" => "templemate_data", "staging" => "templemate_data_staging" },
      DeploymentIdentity::EXPECTED_DATABASES
    )
  end

  # The class above is inert unless something calls it at boot. This fails if
  # the initializer is deleted or stops invoking the guard -- the failure mode
  # where the tests above all still pass and no deployment is actually guarded.
  test "the boot initializer exists and invokes the guard after initialize" do
    initializer = Rails.root.join("config/initializers/deployment_identity.rb")

    assert initializer.exist?,
      "config/initializers/deployment_identity.rb is gone; nothing invokes the guard at boot"

    source = initializer.read
    assert_match(/after_initialize/, source,
      "the guard must run in after_initialize; DeploymentIdentity is autoloaded and " \
      "cannot be referenced during initialization")
    assert_match(/DeploymentIdentity\.new/, source)
    assert_match(/verify!/, source)
  end

  # config/database.yml must name the database for the two guarded environments,
  # because the guard compares a name it reads from configuration rather than
  # from an open connection. A `url:` key here would resolve to nil with no
  # DATABASE_URL on the droplet and hand the choice back to libpq.
  test "database.yml names the database for production and staging" do
    source = Rails.root.join("config/database.yml").read
    guarded = source[/^production:.*/m]

    assert_match(/database: <%= ENV\.fetch\("PGDATABASE", nil\) %>/, guarded)
    assert_no_match(/^\s+url:/, guarded,
      "a url: key here resolves to nil without DATABASE_URL and defeats the guard")
  end
end
