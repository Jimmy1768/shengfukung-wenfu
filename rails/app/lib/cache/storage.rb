# frozen_string_literal: true

# app/lib/cache/storage.rb
#
# Wrapper around the configured Rails cache for short-lived payload storage.
# Default TTL is 5 minutes unless overridden via CACHE_PAYLOAD_TTL.
module Cache
  class Storage
    DEFAULT_TTL_SECONDS = ENV.fetch("CACHE_PAYLOAD_TTL", 5.minutes.to_i).to_i

    class << self
      def read(key)
        Rails.cache.read(namespaced(key))
      end

      def write(key, value, ttl: default_ttl)
        Rails.cache.write(namespaced(key), value, expires_in: ttl)
      end

      def delete(key)
        Rails.cache.delete(namespaced(key))
      end

      def fetch(key, ttl: default_ttl)
        Rails.cache.fetch(namespaced(key), expires_in: ttl) { yield }
      end

      def default_ttl
        DEFAULT_TTL_SECONDS
      end

      # Stable cache key: env + namespace + slug + state key + user/client ids.
      def cache_key(state_key:, user_id:, client_id: nil, slug: nil, extra: nil)
        parts = [
          Rails.env,
          "cache_payload",
          slug.presence || "global",
          state_key,
          "user",
          user_id
        ]
        parts += ["client", client_id] if client_id.present?
        parts += Array(extra) if extra
        parts.join(":")
      end

      private

      def namespaced(key)
        "cache_payload:v1:#{key}"
      end
    end
  end
end
