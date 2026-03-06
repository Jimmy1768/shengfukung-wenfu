# frozen_string_literal: true

require "securerandom"

module Auth
  class OAuthIdentityResolver
    Result = Struct.new(:identity, :user, :created_identity, :linked_existing_user, keyword_init: true)

    def self.resolve_or_link!(provider:, uid:, email:, name:, credentials: {}, metadata: {}, email_verified: nil)
      new(
        provider: provider,
        uid: uid,
        email: email,
        name: name,
        credentials: credentials,
        metadata: metadata,
        email_verified: email_verified
      ).resolve_or_link!
    end

    def initialize(provider:, uid:, email:, name:, credentials:, metadata:, email_verified:)
      @provider = provider.to_s
      @uid = uid.to_s
      @email = normalized_email(email)
      @name = name.to_s.strip
      @credentials = credentials.is_a?(Hash) ? credentials : {}
      @metadata = metadata.is_a?(Hash) ? metadata : {}
      @email_verified = cast_boolean(email_verified)
    end

    def resolve_or_link!
      raise ArgumentError, "provider is required" if @provider.blank?
      raise ArgumentError, "uid is required" if @uid.blank?

      identity = OAuthIdentity.find_or_initialize_by(provider: @provider, provider_uid: @uid)
      created_identity = identity.new_record?

      linked_existing_user = false
      if identity.user.present?
        user = identity.user
      else
        user, linked_existing_user = resolve_user
        identity.user = user
      end

      identity.email = @email
      set_if_supported(identity, :email_verified, @email_verified) unless @email_verified.nil?
      merge_credentials(identity)
      merge_metadata(identity)
      stamp_link_timestamps(identity)
      identity.save!

      Result.new(
        identity: identity,
        user: user,
        created_identity: created_identity,
        linked_existing_user: linked_existing_user
      )
    end

    private

    def resolve_user
      if @email.present?
        existing = User.find_by(email: @email)
        return [existing, true] if existing
      end

      user = User.new(
        email: @email.presence || generated_email,
        english_name: @name.presence || "OAuth User",
        encrypted_password: User.password_hash(SecureRandom.hex(16)),
        metadata: {
          oauth_seeded: true,
          provider: @provider,
          oauth_identity_linked_at: Time.current.iso8601
        }
      )
      user.save!
      [user, false]
    end

    def generated_email
      "#{@provider}_#{SecureRandom.hex(8)}@#{AppConstants::Project.slug}.oauth"
    end

    def merge_credentials(identity)
      if @credentials.present?
        identity.credentials = @credentials
      else
        identity.credentials ||= {}
      end
    end

    def merge_metadata(identity)
      base = identity.metadata.is_a?(Hash) ? identity.metadata : {}
      identity.metadata = base.merge(@metadata).merge("updated_at" => Time.current.iso8601)
    end

    def stamp_link_timestamps(identity)
      now = Time.current
      set_if_supported(identity, :linked_at, identity.read_attribute(:linked_at) || now)
      set_if_supported(identity, :last_login_at, now)
    end

    def set_if_supported(identity, attribute, value)
      return unless identity.has_attribute?(attribute)

      identity[attribute] = value
    end

    def normalized_email(value)
      email = value.to_s.strip.downcase
      email.presence
    end

    def cast_boolean(value)
      return nil if value.nil?

      lowered = value.to_s.strip.downcase
      return true if %w[true 1 yes y].include?(lowered)
      return false if %w[false 0 no n].include?(lowered)

      nil
    end
  end
end
