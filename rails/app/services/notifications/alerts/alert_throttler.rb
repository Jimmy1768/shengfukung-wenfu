# frozen_string_literal: true

module Notifications
  module Alerts
    class AlertThrottler
      WINDOW = 5.minutes

      def self.allow?(key)
        return true unless cache_store

        cache_key = throttle_key(key)
        return false if cache_store.exist?(cache_key)

        cache_store.write(cache_key, true, expires_in: WINDOW)
        true
      rescue => e
        Rails.logger.error "[Notifications::Alerts::AlertThrottler] cache error: #{e.class}: #{e.message}"
        true
      end

      def self.cache_store
        Rails.cache
      rescue NameError
        nil
      end

      def self.throttle_key(key)
        "notifications:alerts:throttle:#{key}"
      end
    end
  end
end
