# frozen_string_literal: true

# Reusable email transport that talks to Brevo via `Emails::AppNotificationEmail`.
module Notifications
  module Email
    class Delivery
      def self.call(user:, body_key:, params: {}, locale: nil, resource_key: nil)
        new(
          user:         user,
          body_key:     body_key,
          params:       params,
          locale:       locale,
          resource_key: resource_key
        ).call
      end

      def initialize(user:, body_key:, params:, locale:, resource_key:)
        @user         = user
        @body_key     = body_key
        @params       = params
        @locale       = locale
        @resource_key = resource_key
      end

      def call
        return false unless @user&.email.present?

        email = Emails::AppNotificationEmail.new(
          user:         @user,
          body_key:     @body_key,
          data:         @params,
          locale:       @locale,
          resource_key: @resource_key
        )

        sent = email.send!
        Rails.logger.info "[Notifications::Email::Delivery] sent=#{sent.inspect} user=#{@user.id} body_key=#{@body_key}"
        unless sent
          Notifications::Alerts::DeliveryFailure.call(
            channel: :email,
            user: @user,
            resource_key: @resource_key,
            details: { reason: 'email_send_false', body_key: @body_key }
          )
        end
        sent
      rescue => e
        Rails.logger.error "[Notifications::Email::Delivery] user=#{@user.id} error=#{e.class}: #{e.message}"
        Notifications::Alerts::DeliveryFailure.call(
          channel: :email,
          user: @user,
          resource_key: @resource_key,
          details: { reason: 'email_exception', message: e.message, body_key: @body_key }
        )
        false
      end
    end
  end
end
