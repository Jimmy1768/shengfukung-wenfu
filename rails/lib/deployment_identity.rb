# frozen_string_literal: true

# Asserts that a process is connected to the database it is supposed to use,
# and refuses to continue when it is not.
#
# Why this exists. Staging and production shared one systemd EnvironmentFile,
# and staging corrected three of its values with an ExecStart prefix. PGDATABASE
# was one of them. Drop that prefix and staging inherited production's
# PGDATABASE and served production's data while every log line still said
# "staging". Nothing failed; that is the whole problem.
#
# The shape below is settled in §4a of ENV_PARTITION_BY_MUTABILITY_PLAN.md,
# ruled by SourceGrid Planning. Three points are load-bearing and each was
# reached by rejecting something more obvious:
#
# 1. It compares the DATABASE NAME, never RAILS_ENV. The hazard is an omission:
#    an instance file can set RAILS_ENV=staging and omit PGDATABASE, the shared
#    file answers in its place, and a RAILS_ENV assertion passes while the
#    process connects to production. A label that correlates with the hazard is
#    not the hazard.
#
# 2. The permissive path keys on DECLARATION, not on being a console. The first
#    version of this guard warned instead of raising at a `rails console`,
#    following the spec's note that a guard which aborts the console is how
#    guards get deleted rather than fixed. That exemption swallowed the defect
#    it was meant to catch: a wrapper named `staging` would warn and open a
#    production console anyway. Nobody asserted anything means the operator's
#    belief is still forming, and a warning informs it. Something asserted an
#    environment and was wrong means the belief is already fixed and false.
#    Presence is what makes a warning readable; it is not what makes it timely.
#
# 3. The permissive path needs TWO POSITIVE conditions -- no declaration AND an
#    interactive stdin -- not merely the absence of a declaration. A declaration
#    can go missing from the wrapper failing before its export, a hand-sourced
#    instance file, `sudo` or `env -i` stripping it, or a refactor moving the
#    export below the exec. Absence as the permissive direction is the original
#    defect's shape one layer up.
#
# It reads a NAME, not a connection. config/database.yml names the database for
# production and staging from PGDATABASE, so the comparison happens before
# anything connects -- which matters, because connecting to the wrong database
# is the event being prevented.
#
# Deliberately a plain object taking plain values: an initializer that can only
# be exercised by booting a real environment is one nobody tests.
class DeploymentIdentity
  # The only environments with an expectation. Anything absent from this map is
  # unguarded: a developer's PGDATABASE is their own business, and the test
  # database is chosen by PGDATABASE_TEST.
  EXPECTED_DATABASES = {
    "production" => "templemate_data",
    "staging" => "templemate_data_staging"
  }.freeze

  # Set by bin/staging to state which environment it believes it is running.
  # It is the wrapper's whole contribution: the wrapper copies no value, so
  # this is a statement of intent rather than a second source of truth.
  DECLARATION_VARIABLE = "WENFU_DECLARED_ENVIRONMENT"

  # An acknowledgement, not a bypass. The guard passes only when the resolved
  # name equals it exactly, so it cannot be used to skip the comparison -- only
  # to state a different expected answer and be held to it.
  #
  # Set it inline on the invocation, never in an instance file, a shared file or
  # a unit. It is not a partition variable and does not belong in that
  # inventory, and every activation is logged at WARN so it cannot be quiet.
  #
  # This class cannot check where it came from: a process cannot tell whether a
  # variable reached it from a command line, an EnvironmentFile or a sourced
  # script. bin/staging closes the gap it can reach, refusing to run when the
  # name appears in either file it sources -- which is where the convention
  # actually rots, someone adding it to an env file to stop the WARN and
  # disarming every later boot.
  #
  # The rule is still not enforced everywhere, and should not be read as if it
  # were: a systemd unit, a shell export or a parent process can set this name
  # and this guard will honour it. Honouring it is safe on its own terms -- the
  # resolved database must still equal it exactly -- but nothing here can tell
  # you that a human meant it this time.
  OVERRIDE_VARIABLE = "WENFU_EXPECTED_DATABASE"

  class Mismatch < StandardError; end

  attr_reader :env, :database, :declared_environment, :override, :tty

  # env                  - Rails environment name, as a String
  # database             - database name resolved from config, as a String
  # declared_environment - the environment something claimed to be running,
  #                        or nil when nothing claimed one
  # override             - an exact database name to expect instead, or nil
  # tty                  - true when stdin is interactive
  def initialize(env:, database:, declared_environment: nil, override: nil, tty: false)
    @env = env.to_s
    @database = database.to_s
    @declared_environment = blank_to_nil(declared_environment)
    @override = blank_to_nil(override)
    @tty = tty
  end

  def declared?
    !declared_environment.nil?
  end

  # What this process claims to be. A declaration outranks Rails.env because a
  # declaration is the more specific statement: something went to the trouble
  # of asserting it.
  def expected_environment
    declared_environment || env
  end

  # The database name this process must be connected to, or nil when there is
  # no expectation to hold it to.
  def expectation
    return override if override

    EXPECTED_DATABASES[expected_environment]
  end

  # False for development and test with nothing declared, where there is
  # nothing to assert. A declaration makes any environment guarded, including
  # one this class has never heard of -- see #ok?.
  def guarded?
    !expectation.nil? || declared?
  end

  def ok?
    return true unless guarded?
    # Declared an environment with no known database and gave no override.
    # Failing closed: an assertion that cannot be checked is not satisfied.
    return false if expectation.nil?

    database == expectation
  end

  # Raises on a mismatch, except where nothing was declared and stdin is
  # interactive, which warns instead. Both conditions are required; see the
  # class comment, point 3.
  def verify!(warner: $stderr, logger: nil)
    log_override(logger)

    return true if ok?
    raise Mismatch, message if declared?

    if tty
      warner.puts(warning)
      return false
    end

    raise Mismatch, message
  end

  def message
    "#{subject} must use the #{expectation_description} database, but config " \
      "resolves to #{shown_database}. #{remedy} Refusing to continue."
  end

  def warning
    [
      "",
      "!! #{'*' * 68}",
      "!! DEPLOYMENT IDENTITY MISMATCH",
      "!! #{subject} expects #{expectation_description}",
      "!! this process is connected to #{shown_database}",
      "!! Commands you run here affect that database, not the one you expect.",
      "!! #{'*' * 68}",
      ""
    ].join("\n")
  end

  private

  def log_override(logger)
    return if override.nil? || logger.nil?

    logger.warn(
      "[deployment_identity] #{OVERRIDE_VARIABLE}=#{override} is set; the " \
        "expected database comes from it rather than from #{expected_environment}. " \
        "This is an acknowledgement, not a bypass: the resolved name must still match."
    )
  end

  def subject
    if declared?
      "#{DECLARATION_VARIABLE}=#{declared_environment} (Rails.env is #{env})"
    else
      env
    end
  end

  def expectation_description
    return "#{override} (from #{OVERRIDE_VARIABLE})" if override
    return expectation if expectation

    "a database this application does not define -- " \
      "#{DECLARATION_VARIABLE}=#{declared_environment} names no known environment, and " \
      "only #{EXPECTED_DATABASES.keys.join(' and ')} have one"
  end

  def shown_database
    database.empty? ? "(blank)" : database
  end

  def remedy
    return "Set #{OVERRIDE_VARIABLE} to the name you actually expect, or correct PGDATABASE." if override

    "PGDATABASE is almost certainly wrong for this checkout: compare it against " \
      "the instance.env beside this checkout (see ops/env/ for the expected shape)."
  end

  def blank_to_nil(value)
    string = value.to_s
    string.empty? ? nil : string
  end
end
