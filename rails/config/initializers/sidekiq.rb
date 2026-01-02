# config/initializers/sidekiq.rb
#
# Basic Sidekiq configuration for the Golden Template.
#
# Redis separation plan:
# - REDIS_SIDEKIQ_URL   : Sidekiq jobs + scheduler   (db 0 by default)
# - REDIS_CACHE_URL     : Rails.cache                (db 1 by default)
# - REDIS_APPSTATE_URL  : app-specific state         (db 2 by default)
#
# In production, set REDIS_SIDEKIQ_URL explicitly per project
# (or per droplet) to avoid cross-app conflicts.

redis_url = ENV.fetch("REDIS_SIDEKIQ_URL", "redis://localhost:6379/0")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end

Rails.logger.info "[Sidekiq] Using Redis at #{redis_url}"
