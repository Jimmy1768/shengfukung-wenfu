# frozen_string_literal: true

module Auth
  class OAuthIdentityUnlinker
    class Error < StandardError; end
    class LastLoginMethodError < Error; end
    class NotLinkedError < Error; end

    def self.unlink!(user:, provider:)
      new(user: user, provider: provider).unlink!
    end

    def initialize(user:, provider:)
      @user = user
      @provider = provider.to_s
    end

    def unlink!
      raise ArgumentError, "user is required" if @user.blank?
      raise ArgumentError, "provider is required" if @provider.blank?

      identity = @user.oauth_identities.find_by(provider: @provider)
      raise NotLinkedError, "No linked identity found for #{@provider.humanize}." if identity.blank?

      if removing_last_login_method?(identity)
        raise LastLoginMethodError, "Add another sign-in method before unlinking this provider."
      end

      identity.destroy!
      identity
    end

    private

    def removing_last_login_method?(identity)
      return false if @user.oauth_identities.where.not(id: identity.id).exists?

      oauth_seeded_user?
    end

    def oauth_seeded_user?
      metadata = @user.metadata.is_a?(Hash) ? @user.metadata : {}
      ActiveModel::Type::Boolean.new.cast(metadata["oauth_seeded"] || metadata[:oauth_seeded])
    end
  end
end
