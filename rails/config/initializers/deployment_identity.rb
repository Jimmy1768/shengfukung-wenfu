# frozen_string_literal: true

# config/initializers/deployment_identity.rb
#
# Refuses to run production or staging against the wrong database. All of the
# reasoning, and the decision about what counts as "wrong", lives in
# lib/deployment_identity.rb so it can be unit tested without booting an
# environment. This file only gathers the three inputs and hands them over.
#
# Two mechanics worth knowing before editing:
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
Rails.application.config.after_initialize do
  db_config = ActiveRecord::Base.configurations.configs_for(
    env_name: Rails.env, name: "primary"
  )

  DeploymentIdentity.new(
    env: Rails.env,
    database: db_config&.database,
    # Set by railties when the process is `rails console`. This is the one
    # process the guard warns rather than stops; see DeploymentIdentity#verify!.
    console: defined?(Rails::Console) ? true : false
  ).verify!
end
