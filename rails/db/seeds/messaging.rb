# frozen_string_literal: true

module Seeds
  module Messaging
    extend self

    def seed
      puts "Seeding messaging data..." # rubocop:disable Rails/Output
      ensure_app_messages
      return unless primary_user

      ensure_push_token(primary_user)
      ensure_notification_preferences(primary_user)
    end

    private

    def primary_user
      @primary_user ||= User.find_by(email: Seeds::AuthCore::PRIMARY_EMAIL)
    end

    def ensure_app_messages
      messages.each do |attributes|
        AppMessage.find_or_initialize_by(key: attributes[:key], channel: attributes[:channel], locale: attributes[:locale]).tap do |message|
          message.assign_attributes(
            payload: attributes[:payload],
            active: attributes.fetch(:active, true),
            metadata: (message.metadata || {}).merge(seed_metadata)
          )
          message.save! if message.changed?
        end
      end
    end

    def ensure_push_token(user)
      PushToken.find_or_initialize_by(user: user, platform: "android", device_name: "Demo mobile device").tap do |token|
        token.assign_attributes(
          token: "demo-mobile-token",
          last_seen_at: Time.current,
          active: true,
          metadata: (token.metadata || {}).merge(seed_metadata)
        )
        token.save! if token.changed?
      end
    end

    def ensure_notification_preferences(user)
      %w[email push].each do |channel|
        NotificationPreference.find_or_initialize_by(user: user, channel: channel).tap do |pref|
          pref.assign_attributes(
            enabled: true,
            alert_sound_enabled: true,
            silent_mode: false,
            metadata: (pref.metadata || {}).merge(seed_metadata)
          )
          pref.save! if pref.changed?
        end
      end
    end

    def messages
      [
        {
          key: "welcome_back",
          channel: "web",
          locale: "en",
          payload: { title: "Welcome", body: "Access admin tools to manage campaigns." }
        },
        {
          key: "sidekiq_alert",
          channel: "web",
          locale: "en",
          payload: { title: "Jobs running", body: "Sidekiq processed 120 jobs in the last hour." },
          active: false
        }
      ]
    end

    def seed_metadata
      {
        seeded_at: Time.current.iso8601,
        seeded_by: "db:seed:messaging"
      }
    end
  end
end
