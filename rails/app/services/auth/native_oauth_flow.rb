# frozen_string_literal: true

module Auth
  class NativeOAuthFlow
    Result = Struct.new(:user, :provider, :profile_required, :account_resolution, keyword_init: true)

    class Error < StandardError; end
    class ConfigurationError < Error; end
    class UpstreamError < Error; end
    class ProviderMismatch < Error; end
    class ClosedAccount < Error; end
    class IdentityError < Error; end
    class InvalidGrant < Error; end
    class ResolutionUnavailable < Error; end

    def initialize(central_client: Auth::CentralOAuthClient.new, transaction: Auth::NativeOAuthTransaction.new)
      @central_client = central_client
      @transaction = transaction
    end

    def start!(provider:, pkce_challenge:, pkce_method:)
      @transaction.validate_start!(provider:, pkce_challenge:, pkce_method:)
      return_url = configured_return_url!
      transaction_token = @transaction.issue!(
        provider:,
        return_url:,
        pkce_challenge:,
        pkce_method:
      )
      response = @central_client.start(
        provider:,
        return_url:,
        tenant_slug: central_tenant_slug,
        pkce_challenge:,
        pkce_method:,
        context: { "native_oauth_contract" => "v1" }
      )
      authorization_url = authorization_url_from(response)
      raise UpstreamError, "central OAuth start response is malformed" if authorization_url.blank?

      {
        oauth: {
          authorization_url:,
          redirect_uri: return_url,
          transaction_token:,
          provider:,
          expires_in: Auth::NativeOAuthTransaction::TTL.to_i
        }
      }
    rescue Auth::CentralOAuthClient::ConfigError
      raise ConfigurationError, "native OAuth is not configured"
    rescue Auth::CentralOAuthClient::RequestError
      raise UpstreamError, "central OAuth start failed"
    end

    def exchange!(code:, transaction_token:, pkce_verifier:)
      raise InvalidGrant, "central OAuth grant is missing" if code.to_s.blank?

      return_url = configured_return_url!
      transaction = @transaction.verify!(
        token: transaction_token,
        return_url:,
        pkce_verifier:
      )
      response = @central_client.exchange(
        tenant_slug: central_tenant_slug,
        params: {
          code: code.to_s,
          provider: transaction.fetch("provider"),
          return_url:,
          pkce_verifier: pkce_verifier.to_s
        }
      )
      raise UpstreamError, "central OAuth exchange response is malformed" unless response.is_a?(Hash) && response.present?

      identity_result = Auth::OAuthExchangeIdentity.resolve!(
        response:,
        expected_provider: transaction.fetch("provider"),
        resolution_surface: "native"
      )
      provider = identity_result.canonical_provider
      Result.new(
        user: identity_result.user,
        provider:,
        profile_required: identity_result.profile_required,
        account_resolution: identity_result.account_resolution
      )
    rescue Auth::CentralOAuthClient::ConfigError
      raise ConfigurationError, "native OAuth is not configured"
    rescue Auth::CentralOAuthClient::RequestError => error
      raise InvalidGrant, "central OAuth grant is invalid" if error.invalid_grant?

      raise UpstreamError, "central OAuth exchange failed"
    rescue Auth::OAuthExchangeIdentity::MissingProvider
      raise UpstreamError, "central OAuth exchange response is malformed"
    rescue Auth::OAuthExchangeIdentity::MissingIdentity
      raise IdentityError, "central OAuth identity is incomplete"
    rescue Auth::OAuthExchangeIdentity::ProviderMismatch
      raise ProviderMismatch, "central OAuth provider mismatch"
    rescue Auth::OAuthExchangeIdentity::ClosedAccount
      raise ClosedAccount, "closed account cannot sign in"
    rescue Auth::OAuthAccountResolution::FeatureDisabled
      raise ResolutionUnavailable, "account resolution is unavailable"
    rescue ActiveRecord::RecordInvalid, ArgumentError
      raise IdentityError, "central OAuth identity is invalid"
    end

    private

    def configured_return_url!
      return_url = AppConstants::OAuth.native_return_url
      raise ConfigurationError, "native OAuth is not configured" if return_url.blank?

      return_url
    end

    # The central auth tenant, which is a deployment identity and not a temple.
    # This used to fall back to the temple's slug, which is what made signing in
    # depend on having one loaded -- and raised NoMethodError through a rescue
    # list that did not cover it once a patron could have none. There is no
    # fallback now: if it is unset, OAuth is misconfigured and says so, the same
    # way a missing return URL does.
    def central_tenant_slug
      slug = ENV["AUTH_TENANT_SLUG"].to_s.strip.presence
      raise ConfigurationError, "native OAuth is not configured" if slug.blank?

      slug
    end

    def authorization_url_from(response)
      return unless response.is_a?(Hash)

      %w[redirect_url authorization_url auth_url url authorize_url].filter_map { |key| response[key].presence }.first
    end

  end
end
