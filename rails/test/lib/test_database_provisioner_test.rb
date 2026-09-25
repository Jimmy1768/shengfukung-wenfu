require "test_helper"
require "stringio"

# The suite provisions its own test database when it is missing, and removes it
# again when the run that created it ends.
#
# These drive TestDatabaseProvisioner with injected collaborators rather than by
# creating and destroying real databases, which is the reason it takes them: the
# cases that matter most -- that it does nothing outside test, and that it can
# never remove a database it did not create -- cannot be exercised safely any
# other way, and an inline begin/rescue in test_helper.rb could not be
# exercised at all.
class TestDatabaseProvisionerTest < ActiveSupport::TestCase
  # Records what was asked of it, including drops. What the assertions below
  # check is not whether a drop happened but which database it was for, because
  # the bound is the design: a run removes only what that run created.
  class FakeTasks
    attr_reader :calls

    def initialize = @calls = []

    def create(config)
      @calls << [:create, config]
    end

    def load_schema(config, *)
      @calls << [:load_schema, config]
    end

    # Recorded rather than refused. Dropping is now legitimate on exactly one
    # path -- the database this run created -- so the assertions below check
    # *whether* a drop happened and for what, instead of treating any drop as a
    # breach.
    def drop(config)
      @calls << [:drop, config]
    end
  end

  def absent = -> { raise ActiveRecord::NoDatabaseError, "does not exist" }
  def present = -> { :ok }
  def never_called = -> { flunk "must not touch the database outside the test environment" }

  # EVERY call in this file passes an explicit `arm:`, and it matters. The real
  # default is arm_removal, which registers an at_exit that removes the database
  # named by the live configuration. A case that reaches the created branch with
  # the real arm would queue a removal of this suite's own database and fire it
  # when the process exits -- destroying, at the end of a green run, a database
  # this run did not create.
  def armed = []
  def arm_into(record) = ->(config) { record << config }

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
        connect: never_called, reconnect: never_called, arm: arm_into([])
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
      connect: present, reconnect: never_called, arm: arm_into([])
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
      connect: absent, reconnect: -> { reconnected = true }, arm: arm_into([])
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
      connect: absent, reconnect: -> {}, arm: arm_into([])
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
        reconnect: never_called, arm: arm_into([])
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
        connect: environment == "test" ? absent : -> {}, reconnect: -> {}, arm: arm_into([])
      )
    end

    assert_equal [:create, :load_schema], tasks.calls.map(&:first)
  end

  # --- criterion 3: the bound, which is the whole design ------------------

  # Removal is armed only from the created branch, and is handed the config
  # captured at the moment this run made the database.
  test "a run that creates the database arms removal for what it created" do
    armed = []

    result = TestDatabaseProvisioner.provision!(
      env: "test", out: StringIO.new, tasks: FakeTasks.new,
      connect: absent, reconnect: -> {}, arm: arm_into(armed)
    )

    assert_equal :created, result
    assert_equal 1, armed.length, "the run created a database and must arm its removal"
  end

  # The assertion the whole design rests on. A found database is used and left
  # alone, so a teardown can never land on another checkout's running suite.
  test "a run that finds the database arms nothing" do
    armed = []
    tasks = FakeTasks.new

    result = TestDatabaseProvisioner.provision!(
      env: "test", out: StringIO.new, tasks: tasks,
      connect: present, reconnect: never_called, arm: arm_into(armed)
    )

    assert_equal :present, result
    assert_empty armed,
      "this run found the database rather than creating it. Arming removal here would " \
      "drop a database this run did not create, which may be another checkout's suite " \
      "mid-run."
    assert_empty tasks.calls.select { |call, _| call == :drop },
      "a found database must never be dropped"
  end

  test "nothing is armed outside the test environment" do
    armed = []

    %w[development staging production].each do |environment|
      TestDatabaseProvisioner.provision!(
        env: environment, out: StringIO.new, tasks: FakeTasks.new,
        connect: never_called, reconnect: never_called, arm: arm_into(armed)
      )
    end

    assert_empty armed
  end

  # --- removal ------------------------------------------------------------

  test "removal drops the config it was given and says so on one line" do
    tasks = FakeTasks.new
    out = StringIO.new
    config = Struct.new(:database).new("wenfu_029_example")

    result = TestDatabaseProvisioner.remove!(
      config: config, env: "test", out: out, tasks: tasks, disconnect: -> {}
    )

    assert_equal :removed, result
    assert_equal [[:drop, config]], tasks.calls
    assert_equal 1, out.string.lines.length, "one line, in the same register as the create line"
    assert_match "wenfu_029_example", out.string
  end

  # Connections have to be released before the drop, or Postgres refuses it and
  # the database survives as a stray.
  test "removal disconnects before dropping" do
    order = []
    tasks = Class.new do
      def initialize(order) = @order = order
      def drop(_config) = @order << :drop
    end.new(order)

    TestDatabaseProvisioner.remove!(
      config: Struct.new(:database).new("wenfu_029_example"), env: "test",
      out: StringIO.new, tasks: tasks, disconnect: -> { order << :disconnect }
    )

    assert_equal %i[disconnect drop], order
  end

  # criterion 5 applies to the drop exactly as it applies to the create.
  %w[development staging production].each do |environment|
    test "removal does nothing at all in #{environment}" do
      tasks = FakeTasks.new

      result = TestDatabaseProvisioner.remove!(
        config: Struct.new(:database).new("templemate_dev"), env: environment,
        out: StringIO.new, tasks: tasks, disconnect: -> { flunk "must not touch #{environment}" }
      )

      assert_equal :skipped_not_test, result
      assert_empty tasks.calls, "nothing may drop a database in #{environment}"
    end
  end

  # A teardown that failed silently would leave a stray nobody knows about; one
  # that raised would turn a green run red over cleanup. It does neither.
  test "a failed removal names the database and does not raise" do
    out = StringIO.new
    tasks = Class.new do
      def drop(_config) = raise ActiveRecord::StatementInvalid, "is being accessed by other users"
    end.new

    result = nil
    assert_nothing_raised do
      result = TestDatabaseProvisioner.remove!(
        config: Struct.new(:database).new("wenfu_029_example"), env: "test",
        out: out, tasks: tasks, disconnect: -> {}
      )
    end

    assert_equal :failed, result
    assert_match "wenfu_029_example", out.string
    assert_match(/dropdb wenfu_029_example/, out.string, "the operator needs the exact command")
  end

  # criterion 4: at_exit rather than an after-suite hook, so a run that fails,
  # errors, or dies while loading test files still removes what it made.
  test "removal is armed through at_exit so a red or broken run still cleans up" do
    source = Rails.root.join("test/test_helper.rb").read
    arm = source[/def arm_removal.*?^  end/m]

    assert arm, "arm_removal must exist or nothing is ever removed"
    assert_match(/at_exit/, arm,
      "a run that fails or errors must still remove what it created; a stray is not " \
      "the price of a red suite")
  end

  # A drop under the test tree used to be forbidden outright. It is now
  # permitted in exactly one file, because creating and removing are one
  # obligation and both halves live in test_helper.rb. Before widening this,
  # read "The Test Database Is Disposable" in ops/protocol/repo_context.md --
  # anyone who finds this in their way has found the guard working.
  #
  # The exception names one file and not a directory. A directory exception
  # would let a drop appear in any new test file without anyone deciding to
  # allow it, which is the guard failing silently rather than being changed.
  SANCTIONED_DROP_PATH = "test/test_helper.rb"

  # Broader than the original, which matched only `DatabaseTasks.drop` and so
  # would not have noticed `tasks.drop(config)` -- the exact form the teardown
  # uses. A guard that cannot see the thing it permits could not have seen an
  # unsanctioned copy of it either.
  DROP_PATTERN = /DatabaseTasks\.drop|\btasks\.drop\b|db:drop|db:test:purge|drop_database|\bdropdb\b/

  test "nothing drops a database except the one sanctioned path" do
    # This file is excluded because it contains the pattern itself, above.
    offenders = Dir.glob(Rails.root.join("test/**/*.rb")).reject do |path|
      path == __FILE__ || Pathname(path).relative_path_from(Rails.root).to_s == SANCTIONED_DROP_PATH
    end.select { |path| File.read(path).match?(DROP_PATTERN) }

    assert_empty offenders.map { |p| Pathname(p).relative_path_from(Rails.root).to_s },
      "only #{SANCTIONED_DROP_PATH} may drop a database, and only the one the run itself " \
      "created. A drop anywhere else can land on a database this run found, which is the " \
      "one thing the teardown is bounded to prevent."
  end

  # Keeps the exception honest. If the teardown is removed, the sanctioned path
  # stops dropping anything and this exception becomes a permission nobody uses
  # -- a hole waiting for the next person who wants one.
  test "the sanctioned path is the one that actually removes the database" do
    source = Rails.root.join(SANCTIONED_DROP_PATH).read

    assert_match DROP_PATTERN, source,
      "#{SANCTIONED_DROP_PATH} no longer removes anything. A run that creates a test " \
      "database must remove it in the same run, and the exception above should not " \
      "outlive the code it was opened for."
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
