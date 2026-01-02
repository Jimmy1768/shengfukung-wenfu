# frozen_string_literal: true

module Notifications
  module Test
    class EmailFailure
      def self.call
        Notifications::Alerts::DeliveryFailure.call(
          channel: :email,
          user: nil,
          resource_key: 'smoke_test_email_failure',
          details: { reason: 'smoke_test', message: 'Simulated email failure' }
        )
      end
    end
  end
end
