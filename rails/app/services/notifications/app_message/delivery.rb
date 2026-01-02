# frozen_string_literal: true

# App message delivery that writes records into the `app_messages` table.
module Notifications
  module AppMessage
    class Delivery
      def self.call(user:, event_key:, data: {}, params: {}, locale: nil, resource_key: nil)
        Rails.logger.info "[Notifications::AppMessage::Delivery] placeholder user=#{user&.id} event=#{event_key}"
        # TODO: Persist the app message, tracking delivery status for in-app feeds.
        true
      rescue => e
        Rails.logger.error "[Notifications::AppMessage::Delivery] user=#{user&.id} error=#{e.class}: #{e.message}"
        false
      end
    end
  end
end
