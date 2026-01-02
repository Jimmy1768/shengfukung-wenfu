# config/initializers/redis_appstate.rb
#
# Dedicated Redis connection for application-specific state:
# - feature flags
# - temporary business data
# - locks / counters / ephemeral coordination
# - short-term memory that does not belong in the DB
#
# This MUST be separate from:
# - Redis used by Sidekiq (REDIS_SIDEKIQ_URL)
# - Redis used by Rails.cache (REDIS_CACHE_URL)
#

require "redis"
require Rails.root.join("app", "lib", "profile", "identity").to_s

redis_appstate_url = ENV.fetch("REDIS_APPSTATE_URL", "redis://localhost:6379/2")

REDIS_APPSTATE = Redis.new(
  url: redis_appstate_url,
  timeout: 2.0,
  read_timeout: 2.0,
  write_timeout: 2.0
)

Rails.logger.info "[RedisAppState] Using Redis appstate at #{redis_appstate_url} "                   "for codename=#{Profile::Identity.app_codename}"
