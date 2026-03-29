# config/puma.rb
#
# Puma configuration for the Golden Template.
#
# NOTES
# ------------------------------------------------------------------
# - This file is intentionally self-contained and does NOT depend on
#   application autoloaded modules (like Profile::Infrastructure),
#   because Puma loads this before the Rails app boots.
#
# - Numeric defaults here should conceptually match the defaults
#   defined in app/lib/profile/infrastructure.rb, but deployments
#   are expected to override via ENV:
#     RAILS_MAX_THREADS, RAILS_MIN_THREADS, WEB_CONCURRENCY, PUMA_PORT
#
# - Port convention:
#     development: 3002 (local dev UI)
#     other envs:  3000 (prod/staging UI)
#

max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count).to_i
threads min_threads_count, max_threads_count

# Port:
# - Use PUMA_PORT if set
# - Otherwise: 3002 in development, 3000 elsewhere
default_port =
  if ENV.fetch("RAILS_ENV", "development") == "development"
    3002
  else
    3000
  end

port ENV.fetch("PORT") {
  ENV.fetch("PUMA_PORT", default_port)
}.to_i

rails_env = ENV.fetch("RAILS_ENV", "development")
environment rails_env

pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# Workers:
# - Disable cluster mode in development to avoid macOS fork issues.
# - Allow WEB_CONCURRENCY to override in other environments.
default_workers =
  if rails_env == "development"
    0
  else
    2
  end

workers_count = ENV.fetch("WEB_CONCURRENCY", default_workers).to_i
workers workers_count if workers_count.positive?

# Preload the application before forking workers (saves memory in prod).
preload_app!

# Allow `rails restart` command to work.
plugin :tmp_restart
