# frozen_string_literal: true

module AppConstants
  module OAuth
    PROVIDERS = {
      google: {
        strategy: :google_oauth2,
        client_id: "OAUTH_GOOGLE_CLIENT_ID",
        client_secret: "OAUTH_GOOGLE_CLIENT_SECRET",
        scope: "userinfo.email,userinfo.profile"
      },
      facebook: {
        strategy: :facebook,
        client_id: "OAUTH_FACEBOOK_CLIENT_ID",
        client_secret: "OAUTH_FACEBOOK_CLIENT_SECRET",
        scope: "email,public_profile"
      },
      apple: {
        strategy: :apple,
        client_id: "OAUTH_APPLE_CLIENT_ID",
        client_secret: "OAUTH_APPLE_CLIENT_SECRET",
        scope: "email name"
      },
      email: {
        client_id: nil,
        client_secret: nil
      }
    }.freeze

    CENTRAL_AUTH_ENV_KEYS = %w[AUTH_BASE_URL AUTH_CLIENT_ID AUTH_CLIENT_SECRET].freeze

    def self.central_auth_enabled?
      CENTRAL_AUTH_ENV_KEYS.all? { |key| ENV[key].present? }
    end

    def self.enabled_providers
      PROVIDERS.each_with_object([]) do |(provider, env_keys), memo|
        next if provider == :email

        client_id = ENV[env_keys[:client_id]]
        client_secret = ENV[env_keys[:client_secret]]
        next if client_id.blank? || client_secret.blank?

        memo << [env_keys[:strategy] || provider, client_id, client_secret, env_keys[:scope]]
      end
    end

    def self.enabled?(provider)
      key = provider.to_sym if provider.respond_to?(:to_sym)
      entry = key ? PROVIDERS[key] : nil
      entry ||= PROVIDERS.values.find { |spec| spec[:strategy] == key }

      return false unless entry

      if entry[:client_id].nil? && entry[:client_secret].nil?
        true
      else
        ENV[entry[:client_id]].present? && ENV[entry[:client_secret]].present?
      end
    end
  end
end
