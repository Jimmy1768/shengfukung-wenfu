
# app/services/system/redis_app_store.rb
#
# Wrapper around the "app state" Redis instance (NOT the Sidekiq Redis).
# Use this for short-lived, non-critical data such as:
# - rate limit buckets
# - ephemeral feature flags
# - cached tokens, etc.
#
# NOTE:
# - Configure REDIS_APPSTATE_URL in env to point at a separate Redis DB.
module System
  class RedisAppStore
    # Returns a Redis client connected to the app-state Redis.
    def self.client
      # TODO: implement using Redis.new(url: ENV["REDIS_APPSTATE_URL"])
      raise NotImplementedError, "System::RedisAppStore.client is not implemented yet"
    end

    # Example helper: read a key.
    def self.get(key)
      # TODO: client.get(key)
      raise NotImplementedError, "System::RedisAppStore.get is not implemented yet"
    end

    # Example helper: write a key with expiry.
    def self.set(key, value, ttl: nil)
      # TODO: client.set(key, value, ex: ttl)
      raise NotImplementedError, "System::RedisAppStore.set is not implemented yet"
    end
  end
end
