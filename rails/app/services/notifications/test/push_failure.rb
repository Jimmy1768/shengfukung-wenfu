# frozen_string_literal: true

module Notifications
  module Test
    class PushFailure
      def self.call
        Notifications::Alerts::DeliveryFailure.call(
          channel: :push,
          user: nil,
          resource_key: 'smoke_test_push_failure',
          details: { reason: 'smoke_test', message: 'Simulated push failure' }
        )
      end
    end
  end
end
