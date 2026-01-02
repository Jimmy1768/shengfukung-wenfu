# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'googleauth'

module Notifications
  # Adapter for Firebase Cloud Messaging HTTP v1 API.
  class FcmClient
    SCOPE = 'https://www.googleapis.com/auth/firebase.messaging'.freeze

    def initialize(project_id: ENV['FIREBASE_PROJECT_ID'])
      @project_id = project_id
      raise ArgumentError, 'Missing FIREBASE_PROJECT_ID' if @project_id.blank?
    end

    def send_to_token(token:, title:, body:, data: {})
      access_token = fetch_access_token
      return false unless access_token

      uri = URI("https://fcm.googleapis.com/v1/projects/#{@project_id}/messages:send")
      payload = build_payload(token: token, title: title, body: body, data: data)

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{access_token}"
      request['Content-Type'] = 'application/json'
      request.body = payload.to_json

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.read_timeout = 15
        http.open_timeout = 5
        http.request(request)
      end

      response.code.to_i == 200
    rescue => e
      Rails.logger.error "[Notifications::FcmClient] error=#{e.class}: #{e.message}"
      false
    end

    private

    def fetch_access_token
      creds = Google::Auth::ServiceAccountCredentials.make_creds(scope: SCOPE)
      creds.fetch_access_token!
      creds.access_token
    rescue => e
      Rails.logger.error "[Notifications::FcmClient] token fetch error: #{e.class}: #{e.message}"
      nil
    end

    def build_payload(token:, title:, body:, data:)
      {
        message: {
          token: token,
          notification: {
            title: title,
            body: body
          },
          data: data.transform_values { |v| v.nil? ? '' : v.to_s },
          android: {
            priority: 'HIGH',
            notification: {
              channel_id: 'important',
              sound: 'default'
            }
          },
          apns: {
            headers: { 'apns-priority' => '10' },
            payload: {
              aps: {
                sound: 'default',
                'content-available': 1
              }
            }
          }
        }
      }
    end
  end
end
