# frozen_string_literal: true

require "base64"
require "digest"
require "securerandom"

module Auth
  # An encrypted, signed envelope keeps short-lived native OAuth context out of
  # browser cookies and avoids a new durable table. Central auth still consumes
  # the provider grant exactly once.
  class NativeOAuthTransaction
    VERSION = 1
    PURPOSE = "auth.native_oauth_transaction.v1"
    TTL = 5.minutes
    PROVIDERS = %w[google apple].freeze
    PKCE_METHOD = "S256"

    class Error < StandardError; end
    class InvalidTransaction < Error; end
    class ExpiredTransaction < InvalidTransaction; end
    class UnsupportedProvider < Error; end
    class InvalidPkce < Error; end

    def self.issue!(provider:, return_url:, pkce_challenge:, pkce_method:)
      new.issue!(provider:, return_url:, pkce_challenge:, pkce_method:)
    end

    def self.verify!(token:, return_url:, provider: nil, pkce_verifier: nil)
      new.verify!(token:, return_url:, provider:, pkce_verifier:)
    end

    def self.validate_start!(provider:, pkce_challenge:, pkce_method:)
      new.validate_start!(provider:, pkce_challenge:, pkce_method:)
    end

    # No temple. Signing in is not temple-scoped: a patron may have none
    # loaded, and nothing about the exchange varies by temple -- the central
    # credentials are per-deployment ENV values. The transaction binds a
    # provider, a return URL and a PKCE challenge, which is what it protects.
    def issue!(provider:, return_url:, pkce_challenge:, pkce_method:)
      validate_issue_inputs!(return_url:, provider:, pkce_challenge:, pkce_method:)

      expires_at = Time.current + TTL
      encryptor.encrypt_and_sign(
        {
          "version" => VERSION,
          "provider" => provider,
          "return_url" => return_url,
          "pkce_challenge" => pkce_challenge,
          "pkce_method" => pkce_method,
          "nonce" => SecureRandom.hex(32),
          "expires_at" => expires_at.to_i
        },
        purpose: PURPOSE
      )
    end

    def validate_start!(provider:, pkce_challenge:, pkce_method:)
      raise UnsupportedProvider, "unsupported provider" unless PROVIDERS.include?(provider.to_s)
      raise InvalidPkce, "PKCE method must be S256" unless pkce_method == PKCE_METHOD
      raise InvalidPkce, "invalid PKCE challenge" unless valid_challenge?(pkce_challenge)
    end

    def verify!(token:, return_url:, provider: nil, pkce_verifier: nil)
      payload = decrypt!(token)
      validate_payload!(payload)
      match!(payload.fetch("return_url"), return_url, "return URL")
      match!(payload.fetch("provider"), provider, "provider") if provider.present?

      if pkce_verifier.present?
        validate_verifier!(pkce_verifier)
        computed = self.class.s256_challenge(pkce_verifier)
        match!(payload.fetch("pkce_challenge"), computed, "PKCE verifier")
      end

      payload
    end

    def self.s256_challenge(verifier)
      Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
    end

    private

    def encryptor
      @encryptor ||= ActiveSupport::MessageEncryptor.new(
        Rails.application.key_generator.generate_key(PURPOSE, ActiveSupport::MessageEncryptor.key_len)
      )
    end

    def decrypt!(token)
      payload = encryptor.decrypt_and_verify(token.to_s, purpose: PURPOSE)
      raise InvalidTransaction, "invalid native OAuth transaction" unless payload.is_a?(Hash)

      payload
    rescue ActiveSupport::MessageEncryptor::InvalidMessage
      raise InvalidTransaction, "invalid native OAuth transaction"
    end

    def validate_issue_inputs!(return_url:, provider:, pkce_challenge:, pkce_method:)
      raise InvalidTransaction, "missing return URL" if return_url.to_s.blank?
      validate_start!(provider:, pkce_challenge:, pkce_method:)
    end

    def validate_payload!(payload)
      # VERSION stays at 1 deliberately. The only change is a field removed, so
      # a token issued before this deploy still satisfies every requirement
      # below; bumping would reject in-flight sign-ins for five minutes and buy
      # nothing, since the check that field fed is the one being removed.
      required = %w[version provider return_url pkce_challenge pkce_method nonce expires_at]
      raise InvalidTransaction, "invalid native OAuth transaction" unless (required - payload.keys).empty?
      raise InvalidTransaction, "unsupported transaction version" unless payload["version"] == VERSION
      raise InvalidTransaction, "unsupported provider" unless PROVIDERS.include?(payload["provider"])
      raise InvalidTransaction, "invalid transaction PKCE method" unless payload["pkce_method"] == PKCE_METHOD
      raise InvalidTransaction, "invalid transaction PKCE challenge" unless valid_challenge?(payload["pkce_challenge"])
      raise InvalidTransaction, "invalid transaction nonce" unless payload["nonce"].to_s.match?(/\A[0-9a-f]{64}\z/)
      raise ExpiredTransaction, "expired native OAuth transaction" if payload["expires_at"].to_i <= Time.current.to_i
    end

    def validate_verifier!(verifier)
      raise InvalidPkce, "invalid PKCE verifier" unless verifier.to_s.match?(/\A[A-Za-z0-9\-._~]{43,128}\z/)
    end

    def valid_challenge?(challenge)
      challenge.to_s.match?(/\A[A-Za-z0-9_-]{43,128}\z/)
    end

    def match!(actual, expected, label)
      expected_value = expected.to_s
      raise InvalidTransaction, "#{label} mismatch" if expected_value.blank? || actual.to_s.bytesize != expected_value.bytesize
      return if ActiveSupport::SecurityUtils.secure_compare(actual.to_s, expected_value)

      raise InvalidTransaction, "#{label} mismatch"
    end
  end
end
