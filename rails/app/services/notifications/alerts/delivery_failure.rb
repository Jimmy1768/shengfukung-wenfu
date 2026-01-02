# frozen_string_literal: true

require 'cgi'

module Notifications
  module Alerts
    class DeliveryFailure
      def self.call(channel:, user:, details: {}, resource_key: nil)
        event_details = build_details(channel, user, details, resource_key)
        Notifications::Logging::EventLogger.log(
          event: 'notifications.alert.delivery_failure',
          details: event_details
        )

        AlertSender.call(
          alert_key: "delivery_failure:#{channel}",
          subject: subject_for(channel, user),
          body: body_for(event_details)
        )
      end

      def self.build_details(channel, user, details, resource_key)
        canonical = {
          channel: channel,
          user_id: user&.id,
          email: user&.email,
          resource: resource_key,
          timestamp: Time.current.utc.iso8601
        }
        canonical.merge(details || {})
    end

    def self.subject_for(channel, user)
      suffix = user ? " for user=#{user.id}" : ""
      "[Alert] #{channel.to_s.capitalize} delivery failure#{suffix}"
    end

      def self.body_for(details)
        rows = details.map do |key, value|
          "#{CGI.escapeHTML(key.to_s)}: #{CGI.escapeHTML(value.to_s)}"
        end
        <<~HTML
          <p>Immediate attention required for #{CGI.escapeHTML(details[:channel].to_s)} delivery.</p>
          <p>#{rows.join('<br>')}</p>
        HTML
      end
    end
  end
end
