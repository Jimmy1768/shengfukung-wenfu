# frozen_string_literal: true

# app/services/cache_payloads/refresher.rb
#
# Convenience wrapper for forcing a payload rebuild (typically from workers).
module CachePayloads
  class Refresher
    def self.call(state_key:, user:, client_checkin:, options: {})
      CachePayloads::FetchService.call(
        state_key: state_key,
        user: user,
        client_checkin: client_checkin,
        force_refresh: true,
        options: options
      )
    end
  end
end
