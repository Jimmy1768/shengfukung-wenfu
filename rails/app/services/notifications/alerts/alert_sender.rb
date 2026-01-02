# frozen_string_literal: true

module Notifications
  module Alerts
    class AlertSender
      def self.call(alert_key:, subject:, body:, throttle_key: nil)
        key = throttle_key || alert_key
        return false unless AlertThrottler.allow?(key)

        recipient = target_email
        return false unless recipient

        html = Notifications::EmailTemplates.marketing_template(body_html: body, footer_text: footer_text)

        Notifications::BrevoClient.new.send_email(
          to: { email: recipient, name: "Alert" },
          subject: subject,
          html: html,
          sender_name: Notifications::EmailConfig::DEFAULT_SENDER_NAME,
          sender_email: Notifications::EmailConfig::DEFAULT_SENDER_EMAIL
        )
      rescue => e
        Rails.logger.error "[Notifications::Alerts::AlertSender] send failed: #{e.class}: #{e.message}"
        false
      end

      def self.target_email
        if Rails.env.production?
          AppConstants::Emails.ops_alert_email
        else
          AppConstants::Emails.dev_app_notification_email
        end
      end

      def self.footer_text
        I18n.t('notifications.alerts.footer', default: 'Please investigate the alert promptly.')
      rescue => _
        'Please investigate the alert promptly.'
      end
    end
  end
end
