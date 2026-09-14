require "test_helper"
require "stringio"

# The suite provisions its own test database when it is missing.
#
# These drive TestDatabaseProvisioner with injected collaborators rather than by
# destroying a real database, which is the reason it takes them: the cases that
# matter most -- that it does nothing outside test, and that it drops nothing --
# cannot be exercised safely any other way, and an inline begin/rescue in
# test_helper.rb could not be exercised at all.
class TestDatabaseProvisionerTest < ActiveSupport::TestCase
  # Records what was asked of it, and refuses anything destructive. `drop` is
  # defined only so that calling it fails loudly rather than raising
  # NoMethodError, which would read like a typo instead of a policy breach.
  class FakeTasks
    attr_reader :calls

    def initialize = @calls = []

    def create(config)
      @calls << [:create, config]
    end

    def load_schema(config, *)
      @calls << [:load_schema, config]
    end

    def drop(_config)
      raise "the suite must never drop a database"
    end
  end

  def absent = -> { raise ActiveRecord::NoDatabaseError, "does not exist" }
  def present = -> { :ok }
  def never_called = -> { flunk "must not touch the database outside the test environment" }

  # --- criterion 3: it cannot run outside test ----------------------------

  # The guard is first and unconditional, so the connection is never even
  # attempted. A provisioning step that can fire in development, staging or
  # production is worse than the problem it solves.
  %w[development staging production].each do |environment|
    test "it does nothing at all in #{environment}" do
      tasks = FakeTasks.new
      out = StringIO.new

      result = TestDatabaseProvisioner.provision!(
        env: environment, out: out, tasks: tasks,
        connect: never_called, reconnect: never_called
      )

      assert_equal :skipped_not_test, result
      assert_empty tasks.calls, "#{environment} must not create anything"
      assert_empty out.string
    end
  end

  # --- criterion 2: present means silent ----------------------------------

  test "an existing database is used as is, with nothing created and nothing printed" do
    tasks = FakeTasks.new
    out = StringIO.new

    result = TestDatabaseProvisioner.provision!(
      env: "test", out: out, tasks: tasks,
      connect: present, reconnect: never_called
    )

    assert_equal :present, result
    assert_empty tasks.calls
    assert_empty out.string, "announcing every run would train people to ignore the line"
  end

  # --- criterion 1, as far as injection can carry it ----------------------

  test "an absent database is created, the schema is loaded, and it says so" do
    tasks = FakeTasks.new
    out = StringIO.new
    reconnected = false

    result = TestDatabaseProvisioner.provision!(
      env: "test", out: out, tasks: tasks,
      connect: absent, reconnect: -> { reconnected = true }
    )

    assert_equal :created, result
    assert_equal %i[create load_schema], tasks.calls.map(&:first),
      "create must come before load_schema"
    assert reconnected, "later code needs a live connection to the new database"
    assert_match(/does not exist/, out.string)
    assert_match(/schema\.rb/, out.string)
  end

  test "it announces on exactly one line" do
    out = StringIO.new

    TestDatabaseProvisioner.provision!(
      env: "test", out: out, tasks: FakeTasks.new,
      connect: absent, reconnect: -> {}
    )

    assert_equal 1, out.string.lines.length
  end

  # Only absence. A connection error that is not NoDatabaseError -- bad
  # credentials, no server -- must surface, not be answered by creating things.
  test "it does not create anything for an error that is not absence" do
    tasks = FakeTasks.new

    assert_raises(ActiveRecord::ConnectionNotEstablished) do
      TestDatabaseProvisioner.provision!(
        env: "test", out: StringIO.new, tasks: tasks,
        connect: -> { raise ActiveRecord::ConnectionNotEstablished, "no server" },
        reconnect: never_called
      )
    end

    assert_empty tasks.calls
  end

  # --- criterion 4: nothing drops -----------------------------------------

  test "no provisioning path asks for a drop" do
    tasks = FakeTasks.new

    %w[development test].each do |environment|
      TestDatabaseProvisioner.provision!(
        env: environment, out: StringIO.new, tasks: tasks,
        connect: environment == "test" ? absent : -> {}, reconnect: -> {}
      )
    end

    assert_equal [:create, :load_schema], tasks.calls.map(&:first)
  end

  # Dropping is the operator's. A drop introduced anywhere under the test tree
  # would make a suite run destructive, which is the one thing this change must
  # not become while making absence recoverable.
  test "nothing in the test tree drops a database" do
    # This file is excluded because it contains the pattern itself, in the line
    # below. It is not a hole: FakeTasks#drop raises, so any drop reached from
    # these tests fails loudly rather than passing quietly.
    offenders = Dir.glob(Rails.root.join("test/**/*.rb")).reject { |path| path == __FILE__ }.select do |path|
      File.read(path).match?(/DatabaseTasks\.drop|db:drop|db:test:purge|drop_database/)
    end

    assert_empty offenders.map { |p| Pathname(p).relative_path_from(Rails.root).to_s },
      "the suite must never drop a database; dropping is the operator's"
  end

  # --- wiring --------------------------------------------------------------

  # The module is inert unless test_helper calls it, and it has to be called
  # before rails/test_help, which is what raises on an absent database.
  test "test_helper invokes the provisioner before rails/test_help" do
    source = Rails.root.join("test/test_helper.rb").read

    call = source.index("TestDatabaseProvisioner.provision!")
    test_help = source.index('require "rails/test_help"')

    assert call, "test_helper must invoke the provisioner or nothing provisions"
    assert test_help
    assert call < test_help,
      "provisioning must run before rails/test_help, which is what raises NoDatabaseError"
  end
end
