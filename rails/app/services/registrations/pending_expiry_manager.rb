# frozen_string_literal: true

module Registrations
  class PendingExpiryManager
    def self.cancel_stale_unpaid!(now: Time.current)
      ExpiryNotificationDispatcher.dispatch_expiring_soon!(now:)
      cancelled = TempleRegistration.cancel_expired_unpaid!(now:)
      ExpiryNotificationDispatcher.dispatch_expired!(now:)
      cancelled
    end
  end
end
