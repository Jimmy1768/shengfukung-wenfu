# frozen_string_literal: true

module Auth
  class OAuthIdentityLinker
    class Error < StandardError; end
    class ConflictError < Error; end
    class ProviderAlreadyLinkedError < Error; end

    Result = Struct.new(:identity, :created_identity, :already_linked, keyword_init: true)

    def self.link!(user:, provider:, uid:, email:, credentials: {}, metadata: {}, email_verified: nil)
      new(
        user: user,
        provider: provider,
        uid: uid,
        email: email,
        credentials: credentials,
        metadata: metadata,
        email_verified: email_verified
      ).link!
    end

    def initialize(user:, provider:, uid:, email:, credentials:, metadata:, email_verified:)
      @user = user
      @provider = provider.to_s
      @uid = uid.to_s
      @email = normalize_email(email)
      @credentials = credentials.is_a?(Hash) ? credentials : {}
      @metadata = metadata.is_a?(Hash) ? metadata : {}
      @email_verified = ActiveModel::Type::Boolean.new.cast(email_verified) unless email_verified.nil?
    end

    def link!
      raise ArgumentError, "user is required" if @user.blank?
      raise ArgumentError, "provider is required" if @provider.blank?
      raise ArgumentError, "uid is required" if @uid.blank?

      existing = OAuthIdentity.find_by(provider: @provider, provider_uid: @uid)
      if existing.present? && existing.user_id != @user.id
        raise ConflictError, "That #{provider_label} identity is already linked to another account."
      end

      identity = existing || @user.oauth_identities.find_or_initialize_by(provider: @provider)
      created_identity = identity.new_record?

      if identity.persisted? && identity.provider_uid.present? && identity.provider_uid != @uid
        raise ProviderAlreadyLinkedError, "#{provider_label} is already linked to this account."
      end

      already_linked = identity.persisted? && identity.provider_uid == @uid

      identity.user = @user
      identity.provider_uid = @uid
      identity.email = @email
      identity.email_verified = @email_verified unless @email_verified.nil?
      identity.credentials = @credentials.presence || identity.credentials || {}
      identity.metadata = merged_metadata(identity)
      identity.linked_at ||= Time.current if identity.has_attribute?(:linked_at)
      identity.last_login_at = Time.current if identity.has_attribute?(:last_login_at)
      identity.save!

      Result.new(identity: identity, created_identity: created_identity, already_linked: already_linked)
    end

    private

    def merged_metadata(identity)
      base = identity.metadata.is_a?(Hash) ? identity.metadata : {}
      base.merge(@metadata).merge("updated_at" => Time.current.iso8601)
    end

    def normalize_email(value)
      email = value.to_s.strip.downcase
      email.presence
    end

    def provider_label
      @provider.to_s.humanize
    end
  end
end
