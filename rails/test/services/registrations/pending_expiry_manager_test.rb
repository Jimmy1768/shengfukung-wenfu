# frozen_string_literal: true

require "test_helper"

module Registrations
  class PendingExpiryManagerTest < ActiveSupport::TestCase
    test "cancel_stale_unpaid dispatches reminders and delegates cancellation" do
      now = Time.current
      calls = []

      ExpiryNotificationDispatcher.stub(:dispatch_expiring_soon!, ->(now:) { calls << :expiring_soon }) do
        ExpiryNotificationDispatcher.stub(:dispatch_expired!, ->(now:) { calls << :expired }) do
          TempleRegistration.stub(:cancel_expired_unpaid!, ->(now:) { calls << :cancel; 3 }) do
            assert_equal 3, PendingExpiryManager.cancel_stale_unpaid!(now:)
          end
        end
      end

      assert_equal %i[expiring_soon cancel expired], calls
    end
  end
end
