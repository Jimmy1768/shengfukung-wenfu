# frozen_string_literal: true

require 'cgi'

module Notifications
  module Alerts
    class SidekiqFailureHandler
      def self.call(exception, context)
        return unless exception && context

        job_class = context['class'] || context[:class] || 'unknown'
        arguments = context['args'] || context[:args]
        timestamp = Time.current.utc.iso8601

        event_details = {
          job_class: job_class,
          exception: exception.class.to_s,
          message: exception.message,
          args: arguments.inspect,
          timestamp: timestamp
        }

        Notifications::Logging::EventLogger.log(
          event: 'notifications.sidekiq.failure',
          details: event_details
        )

        AlertSender.call(
          alert_key: "sidekiq_failure:#{job_class}",
          subject: "[Alert] Sidekiq failure #{job_class}",
          body: <<~HTML
            <p>Sidekiq job <strong>#{job_class}</strong> failed at #{CGI.escapeHTML(timestamp)}.</p>
            <p>Exception: #{CGI.escapeHTML(exception.class.to_s)} – #{CGI.escapeHTML(exception.message)}</p>
            <p>Arguments: #{CGI.escapeHTML(arguments.inspect)}</p>
          HTML
        )
      rescue => e
        Rails.logger.error "[Notifications::Alerts::SidekiqFailureHandler] error: #{e.class}: #{e.message}"
      end
    end
  end
end
