# frozen_string_literal: true

require "test_helper"

module Registrations
  class PendingExpiryManagerTest < ActiveSupport::TestCase
    test "cancel_stale_unpaid delegates to registration expiry" do
      now = Time.current
      TempleRegistration.stub(:cancel_expired_unpaid!, 3) do
        assert_equal 3, PendingExpiryManager.cancel_stale_unpaid!(now:)
      end
    end
  end
end
