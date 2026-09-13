# frozen_string_literal: true

# Asserts that a deployment is connected to the database its environment is
# supposed to use, and refuses to continue when it is not.
#
# Why this exists. Staging and production shared one systemd EnvironmentFile,
# and staging corrected three of its values with an ExecStart prefix. PGDATABASE
# was one of them. Drop that prefix -- a unit file edit, a redeploy, a typo --
# and staging inherited production's PGDATABASE and served production's data
# while every log line still said "staging". Nothing failed; that is the whole
# problem. This class makes the mismatch loud.
#
# It is deliberately a plain object taking three plain values. An initializer
# that can only be exercised by booting a real environment is one nobody tests,
# so the decision lives here where a unit test can drive it directly, and
# config/initializers/deployment_identity.rb only gathers the inputs.
#
# It reads a NAME, not a connection. config/database.yml names the database for
# production and staging from PGDATABASE, so the expected/actual comparison
# happens before anything connects -- which matters, because connecting to the
# wrong database is the event being prevented.
class DeploymentIdentity
  # The only environments with an expectation. Anything absent from this map is
  # unguarded: a developer's PGDATABASE is their own business, and the test
  # database is chosen by PGDATABASE_TEST.
  EXPECTED_DATABASES = {
    "production" => "templemate_data",
    "staging" => "templemate_data_staging"
  }.freeze

  class Mismatch < StandardError; end

  attr_reader :env, :database, :console

  # env      - the Rails environment name, as a String
  # database - the database name resolved from config, as a String
  # console  - true when this process is an interactive console
  def initialize(env:, database:, console: false)
    @env = env.to_s
    @database = database.to_s
    @console = console
  end

  # False for development and test, where there is nothing to assert.
  def guarded?
    EXPECTED_DATABASES.key?(env)
  end

  def expected_database
    EXPECTED_DATABASES[env]
  end

  def ok?
    return true unless guarded?

    database == expected_database
  end

  # Raises on a mismatch, except in a console, where it warns instead.
  #
  # The exclusion is narrow and deliberate. A console is the tool you need to
  # diagnose the very misconfiguration this guard detects, and a guard that
  # takes that tool away is one that gets deleted rather than fixed. An operator
  # at a console is also present to read a warning, which a unit starting
  # unattended is not. Everything else -- the server, runner, rake, db:migrate,
  # workers -- is stopped, because on a correctly configured deployment this
  # guard never fires at all, so it never stands in the way of legitimate work.
  #
  # Residual risk, stated rather than hidden: a console can still be driven
  # against the wrong database. The warning names both databases so that is a
  # decision the operator makes with the facts in front of them.
  def verify!(warner: $stderr)
    return true if ok?

    raise Mismatch, message unless console

    warner.puts(warning)
    false
  end

  def message
    "#{env} must use the #{expected_database} database, but config resolves to " \
      "#{database.empty? ? '(blank)' : database}. PGDATABASE is almost certainly " \
      "wrong for this checkout: compare it against the instance.env beside this " \
      "checkout (see ops/env/ for the expected shape). Refusing to continue."
  end

  def warning
    [
      "",
      "!! #{'*' * 68}",
      "!! DEPLOYMENT IDENTITY MISMATCH",
      "!! #{env} expects #{expected_database}",
      "!! this console is connected to #{database.empty? ? '(blank)' : database}",
      "!! Commands you run here affect that database, not the one you expect.",
      "!! #{'*' * 68}",
      ""
    ].join("\n")
  end
end
