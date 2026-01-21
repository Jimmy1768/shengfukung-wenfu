# frozen_string_literal: true

# app/services/cache_payloads/base_builder.rb
#
# Parent class for payload builders. Subclasses should implement `state_key`
# and `build_payload` to return a JSON-ready hash/array.
module CachePayloads
  class BaseBuilder
    attr_reader :user, :client_checkin, :options

    def initialize(user:, client_checkin:, options: {})
      @user = user
      @client_checkin = client_checkin
      @options = options || {}
    end

    def state_key
      raise NotImplementedError, "#{self.class.name} must define #state_key"
    end

    def build_payload
      raise NotImplementedError, "#{self.class.name} must define #build_payload"
    end

    # Optional TTL override per builder.
    def ttl_seconds
      Cache::Storage.default_ttl
    end

    # Helper slug resolver so builders can scope queries.
    def slug
      options[:slug].presence || user.try(:temple)&.slug
    end
  end
end
