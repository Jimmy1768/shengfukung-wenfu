# frozen_string_literal: true

module AppConstants
  module Emails
    DEFAULT_NO_REPLY           = 'no-reply@sourcegridlabs.com'.freeze
    DEFAULT_SUPPORT            = 'support@sourcegridlabs.com'.freeze
    DEV_APP_NOTIFICATION       = 'jimmy.chuang@outlook.com'.freeze
    OPS_ALERT                  = 'admin@sourcegridlabs.com'.freeze
    THREDDED_NOTIFICATION      = 'no-reply@sourcegridlabs.com'.freeze
    CONTACT_INBOX              = 'admin@sourcegridlabs.com'.freeze

    class << self
      def dev_app_notification_email
        ENV['DEV_APP_NOTIFICATION_EMAIL'].presence || DEV_APP_NOTIFICATION
      end

      def ops_alert_email
        ENV.fetch('OPS_ALERT_EMAIL', OPS_ALERT)
      end

      def brevo_sender_email
        ENV.fetch('BREVO_SENDER_EMAIL', DEFAULT_NO_REPLY)
      end

      def no_reply
        DEFAULT_NO_REPLY
      end

      def support_email
        DEFAULT_SUPPORT
      end

      def thredded_sender
        THREDED_NOTIFICATION
      end

      def contact_inbox
        CONTACT_INBOX
      end
    end
  end
end
