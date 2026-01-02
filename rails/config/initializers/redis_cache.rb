# config/initializers/redis_cache.rb
#
# Redis cache configuration for the Golden Template.
#

require Rails.root.join("app", "lib", "profile", "identity").to_s

redis_cache_url = ENV.fetch("REDIS_CACHE_URL", "redis://localhost:6379/1")

Rails.application.config.cache_store = :redis_cache_store, {
  url: redis_cache_url,
  namespace: "#{Profile::Identity.app_codename}_cache",
  error_handler: -> (method:, returning:, exception:) {
    Rails.logger.error(
      "[RedisCache] #{method} failed: #{exception.class} #{exception.message}"
    )
  }
}

Rails.logger.info "[RedisCache] Using Redis cache at #{redis_cache_url} "                   "namespace=#{Profile::Identity.app_codename}_cache"
