# frozen_string_literal: true

# config/initializers/deployment_identity.rb
#
# Refuses to run against the wrong database. All of the reasoning, and the
# decision about what counts as wrong, lives in lib/deployment_identity.rb so it
# can be unit tested without booting an environment. This file only gathers the
# five inputs and hands them over.
#
# Three mechanics worth knowing before editing:
#
# 1. This runs in `after_initialize`, not in the body of the initializer.
#    DeploymentIdentity is autoloaded from lib/, and autoloading a reloadable
#    constant during initialization is not allowed -- the check would work in
#    production, where eager loading has already defined it, and break in
#    development. after_initialize runs after eager loading in every
#    environment, and still runs long before Puma accepts a request.
#
# 2. The database name comes from the resolved configuration, not from a
#    connection. config/database.yml names it from PGDATABASE for production and
#    staging, so this compares names while the socket is still closed. Guarding
#    after connecting would mean the wrong database had already been opened.
#
# 3. `$stdin.tty?` is the interactivity probe, and it fails closed. Observed
#    2026-09-13 in this repository and reproduced independently by SourceGrid
#    Planning in theirs: false from an agent session directly, under
#    `bundle exec`, and through a pipe; true under a pty allocated by
#    `script(1)`, and true through a plain `exec`, which is the shape
#    bin/staging ends with, so a real terminal survives the wrapper.
#
#    Two consequences. The permissive path is structurally unreachable from an
#    agent session, which matters because the main non-human operator of this
#    repository is one -- it is excluded by construction rather than by policy.
#    And every way of losing a TTY (`ssh` without `-t`, a pipe, a script, a
#    stripped environment) lands on refuse, so no configuration accidentally
#    opens the permissive path.
#
#    Evidence limit: `tty?` interrogates the file descriptor, not what is
#    attached beyond it. That a given operator's path supplies a pty is an
#    observation, not an assumption -- and where it does not, the guard refuses,
#    which is the safe direction.
Rails.application.config.after_initialize do
  db_config = ActiveRecord::Base.configurations.configs_for(
    env_name: Rails.env, name: "primary"
  )

  DeploymentIdentity.new(
    env: Rails.env,
    database: db_config&.database,
    declared_environment: ENV[DeploymentIdentity::DECLARATION_VARIABLE],
    override: ENV[DeploymentIdentity::OVERRIDE_VARIABLE],
    tty: $stdin.tty?
  ).verify!(logger: Rails.logger)
end
