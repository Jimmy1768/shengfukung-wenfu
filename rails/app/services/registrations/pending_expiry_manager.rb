# frozen_string_literal: true

module Registrations
  class PendingExpiryManager
    def self.cancel_stale_unpaid!(now: Time.current)
      TempleRegistration.cancel_expired_unpaid!(now:)
    end
  end
end
