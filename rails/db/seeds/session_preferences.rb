# frozen_string_literal: true

require "digest"

require Rails.root.join("db", "seeds", "auth_core")
require Rails.root.join("app", "lib", "app_constants", "locales").to_s

module Seeds
  module SessionPreferences
    extend self

    def seed
      puts "Seeding session preferences..." # rubocop:disable Rails/Output
      return unless primary_user

      @locale_data = AppConstants::Locales.find(AppConstants::Locales::DEFAULT_CODE)

      ensure_user_preference(primary_user)
      ensure_privacy_setting(primary_user)
      ensure_client_checkin(primary_user)
      ensure_refresh_token(primary_user)
    end

    private

    def primary_user
      @primary_user ||= User.find_by(email: Seeds::AuthCore::PRIMARY_EMAIL)
    end

    def ensure_user_preference(user)
      UserPreference.find_or_initialize_by(user: user).tap do |preference|
        preference.assign_attributes(
          locale: @locale_data[:code],
          timezone: @locale_data[:timezone],
          currency: @locale_data[:currency],
          theme: "light",
          temperature_unit: "C",
          measurement_system: "metric",
          twenty_four_hour_time: true,
          metadata: (preference.metadata || {}).merge(seed_metadata)
        )
        preference.save! if preference.changed?
      end
    end

    def ensure_privacy_setting(user)
      PrivacySetting.find_or_initialize_by(user: user).tap do |setting|
        setting.assign_attributes(
          share_data_with_partners: false,
          third_party_tracking_enabled: false,
          email_tracking_opt_in: true,
          metadata: (setting.metadata || {}).merge(seed_metadata)
        )
        setting.save! if setting.changed?
      end
    end

    def ensure_client_checkin(user)
      ClientCheckin.find_or_initialize_by(client_id: "demo-web", client_type: "browser").tap do |checkin|
        checkin.assign_attributes(
          user: user,
          last_ping_at: Time.current,
          metadata: (checkin.metadata || {}).merge(seed_metadata)
        )
        if checkin.respond_to?(:cache_revision=)
          checkin.cache_revision ||= 1
        elsif checkin.respond_to?(:cache_version=)
          checkin.cache_version ||= 1
        end
        checkin.save! if checkin.changed?
      end
    end

    def ensure_refresh_token(user)
      RefreshToken.find_or_initialize_by(device_id: "demo-browser").tap do |token|
        token.assign_attributes(
          user: user,
          token_digest: Digest::SHA256.hexdigest("#{user.id}-refresh-#{Time.current.to_i}"),
          device_name: "Demo Browser",
          platform: "web",
          expires_at: 30.days.from_now,
          metadata: (token.try(:metadata) || {}).merge(seed_metadata)
        )
        token.save! if token.changed?
      end
    end

    def seed_metadata
      {
        seeded_at: Time.current.iso8601,
        seeded_by: "db:seed:session_preferences"
      }
    end
  end
end
