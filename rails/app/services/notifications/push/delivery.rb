# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'ostruct'

module Notifications
  module Push
    class Delivery
      EXPO_URL = URI.parse('https://exp.host/--/api/v2/push/send')

      def self.call(user:, title_key:, body_key:, params: {}, data: {}, locale: nil, resource_key: nil)
        return false unless user

        devices = push_device_records_for(user)
        return false if devices.empty?

        locale ||= resolve_locale(user)
        title = localized_text(title_key, locale, {})
        body  = localized_text(body_key, locale, params)

        attempted = false

        devices.each do |device|
          attempted |= send_to_device(device, title, body, data, locale)
        end

        Notifications::Logging::EventLogger.log(
          event: 'notifications.push.attempted',
          details: { user_id: user.id, attempted: attempted, device_count: devices.size, resource: resource_key }
        )

        unless attempted
          Notifications::Alerts::DeliveryFailure.call(
            channel: :push,
            user: user,
            resource_key: resource_key,
            details: { reason: 'no_push_sent', event: body_key }
          )
        end

        attempted
      rescue => e
        Rails.logger.error "[Notifications::Push::Delivery] user=#{user.id} error=#{e.class}: #{e.message}"
        Notifications::Logging::EventLogger.log(
          event: 'notifications.push.error',
          level: :error,
          details: { user_id: user.id, error: e.class.to_s, message: e.message }
        )
        Notifications::Alerts::DeliveryFailure.call(
          channel: :push,
          user: user,
          resource_key: resource_key,
          details: { reason: 'push_exception', message: e.message }
        )
        false
      end

      class << self
        private

        def send_to_device(device, title, body, data, locale)
          if device.respond_to?(:fcm_token) && device.fcm_token.present?
            send_via_fcm(device.fcm_token, title, body, data, device_id: device.id, locale: locale)
          elsif device.respond_to?(:expo_push_token) && device.expo_push_token.present?
            send_via_expo(device.expo_push_token, title, body, data, device_id: device.id)
          elsif device.respond_to?(:apns_token) && device.apns_token.present?
            log_apns_placeholder(device.apns_token, device.id)
            true
          else
            false
          end
        end

        def send_via_fcm(token, title, body, data, device_id:, locale:)
          return false unless fcm_client

          success = fcm_client.send_to_token(
            token: token,
            title: title,
            body:  body,
            data:  data.merge(locale: locale.to_s)
          )

          log_result('fcm', token, success, device_id, title)
          success
        end

        def send_via_expo(token, title, body, data, device_id:)
          payload = {
            to: token,
            title: title,
            body: body,
            sound: 'default',
            channelId: 'important',
            data: data
          }

          response = http_post(EXPO_URL, payload)
          success = response&.code.to_i == 200
          log_result('expo', token, success, device_id, title, response_body(response))
          success
        rescue => e
          Rails.logger.error "[Notifications::Push::Delivery] Expo error=#{e.class}: #{e.message}"
          Notifications::Logging::EventLogger.log(event: 'notifications.push.expo_error', level: :warn, details: { message: e.message, device_id: device_id })
          false
        end

        def log_apns_placeholder(token, device_id)
          Notifications::Logging::EventLogger.log(
            event: 'notifications.push.apns_placeholder',
            details: { token: token[0..8], device_id: device_id }
          )
        end

        def log_result(provider, token, success, device_id, title, response_body = nil)
          Notifications::Logging::EventLogger.log(
            event: 'notifications.push.result',
            details: {
              provider: provider,
              token_snippet: token[0..8],
              success: success,
              device_id: device_id,
              title: title,
              response: response_body
            }
          )
        end

        def http_post(uri, payload)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
          request.body = payload.to_json
          http.request(request)
        end

        def response_body(response)
          return unless response
          response.body
        end

        def push_device_records_for(user)
          if user.respond_to?(:push_devices)
            user.push_devices.where(enabled: true)
          elsif user.respond_to?(:expo_push_token)
            [OpenStruct.new(expo_push_token: user.expo_push_token, fcm_token: user.fcm_token)]
          else
            []
          end
        rescue => e
          Rails.logger.error "[Notifications::Push::Delivery] device fetch error: #{e.message}"
          []
        end

        def localized_text(key, locale, params = {})
          I18n.with_locale(locale) { I18n.t(key, **params.symbolize_keys) }
        end

        def resolve_locale(user)
          user.user_preference&.data&.dig('locale') || user.try(:locale) || I18n.default_locale
        end

        def fcm_client
          @fcm_client ||= Notifications::FcmClient.new
        rescue ArgumentError => e
          Rails.logger.warn "[Notifications::Push::Delivery] FCM disabled: #{e.message}"
          nil
        end
      end
    end
  end
end
