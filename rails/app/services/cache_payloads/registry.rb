# frozen_string_literal: true

# app/services/cache_payloads/registry.rb
#
# Central mapping of state keys -> builder classes. Builders register
# themselves (typically in their file) by calling `.register`.
module CachePayloads
  class Registry
    class << self
      def register(state_key, builder_class)
        registry[state_key.to_s] = builder_class
      end

      def fetch(state_key)
        registry.fetch(state_key.to_s) do
          raise KeyError, "No cache payload builder registered for #{state_key}"
        end
      end

      def registered_keys
        registry.keys
      end

      def reset!
        @registry = {}
      end

      private

      def registry
        @registry ||= {}
      end
    end
  end
end
