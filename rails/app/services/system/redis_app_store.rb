# app/services/system/redis_app_store.rb
#
# Wrapper around the "app state" Redis instance (NOT the Sidekiq Redis).
# Use this for short-lived, non-critical data such as:
# - rate limit buckets
# - ephemeral feature flags
# - cached tokens, etc.
# - temporary workflow/session state
#
# NOTE:
# - Configure REDIS_APPSTATE_URL in env to point at a separate Redis DB.
module System
  class RedisAppStore
    KEY_PREFIX = "#{Profile::Identity.app_codename}:appstate"

    # Returns a Redis client connected to the app-state Redis.
    def self.client
      REDIS_APPSTATE
    end

    def self.get(key)
      client.get(namespaced_key(key))
    end

    def self.set(key, value, ttl: nil)
      options = ttl.present? ? { ex: ttl.to_i } : {}

      client.set(namespaced_key(key), value, **options)
    end

    def self.delete(key)
      client.del(namespaced_key(key))
    end

    def self.namespaced_key(key)
      clean_key = key.to_s.strip
      raise ArgumentError, "Redis app-state key cannot be blank" if clean_key.blank?

      "#{KEY_PREFIX}:#{clean_key}"
    end
  end
end
