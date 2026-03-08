# frozen_string_literal: true

require "base64"
require "json"
require "securerandom"

module Auth
  class CentralOAuthController < ActionController::Base
    protect_from_forgery with: :exception
    skip_before_action :verify_authenticity_token

    PENDING_CONTEXT_SESSION_KEY = "central_oauth_pending"
    ACCOUNT_TEMPLE_SESSION_KEY = "account_active_temple_slug"
    ACCOUNT_SESSION_KEY = AppConstants::Sessions.key(:account)
    ADMIN_TEMPLE_SESSION_KEY = AppConstants::Sessions.key(:admin_temple)

    PROVIDER_ALIASES = {
      "google" => "google",
      "google_oauth2" => "google",
      "apple" => "apple",
      "facebook" => "facebook"
    }.freeze

    PROVIDER_TO_IDENTITY = {
      "google" => "google_oauth2",
      "apple" => "apple",
      "facebook" => "facebook"
    }.freeze

    def start
      provider = normalize_provider_param(params[:provider])
      raise ArgumentError, "Unsupported provider" unless provider.present?

      pending = {
        "surface" => requested_surface,
        "temple" => params[:temple].presence,
        "origin" => params[:origin].presence,
        "intent" => normalized_intent(params[:intent]),
        "nonce" => SecureRandom.hex(8)
      }.compact
      session[PENDING_CONTEXT_SESSION_KEY] = pending

      response = central_auth_client.start(
        provider: provider,
        return_url: central_oauth_callback_url,
        tenant_slug: central_tenant_slug(pending),
        context: pending
      )

      redirect_url =
        response["redirect_url"].presence ||
        response["authorization_url"].presence ||
        response["auth_url"].presence ||
        response["url"].presence ||
        response["authorize_url"].presence

      raise Auth::CentralOAuthClient::RequestError, "Missing redirect URL from central auth" if redirect_url.blank?

      redirect_to redirect_url, allow_other_host: true
    rescue StandardError => e
      Rails.logger.error("[CentralOAuthController#start] #{e.class}: #{e.message}")
      redirect_to fallback_login_path(requested_surface), alert: "OAuth login is unavailable right now."
    end

    def callback
      account_user = current_account_user
      pending = session.delete(PENDING_CONTEXT_SESSION_KEY) || {}

      if link_intent?(pending) && !oauth_account_linking_enabled_for?(account_user)
        return redirect_to(
          fallback_redirect_path(pending),
          alert: I18n.t("account.oauth.flash.disabled")
        )
      end

      if params[:error].present?
        return redirect_to(
          fallback_redirect_path(pending),
          alert: "OAuth login failed: #{params[:error]}"
        )
      end

      exchange_payload = {
        code: params[:code],
        state: params[:state],
        provider: normalize_provider_param(params[:provider]),
        return_url: central_oauth_callback_url,
        query: request.query_parameters
      }.compact

      response = central_auth_client.exchange(params: exchange_payload, tenant_slug: central_tenant_slug(pending))
      identity, user, link_result = resolve_identity_from_exchange!(response, pending, account_user)

      unless link_intent?(pending)
        establish_session_for(user, pending)
      end

      log_oauth_event(
        link_intent?(pending) ? "account.oauth.linked" : "account.oauth.signed_in",
        user: user,
        pending: pending,
        provider: identity.provider,
        identity_id: identity.id,
        linked_existing_user: link_result.respond_to?(:linked_existing_user) ? link_result.linked_existing_user : nil
      )

      redirect_to success_redirect_path(pending), notice: success_notice(pending, link_result, identity)
    rescue Auth::OAuthIdentityLinker::ConflictError, Auth::OAuthIdentityLinker::ProviderAlreadyLinkedError => e
      Rails.logger.warn("[CentralOAuthController#callback] #{e.class}: #{e.message}")
      log_oauth_event(
        "account.oauth.link_conflict",
        user: account_user,
        pending: pending,
        provider: normalize_provider_param(params[:provider]),
        error: e.message
      )
      redirect_to fallback_redirect_path(pending), alert: e.message
    rescue StandardError => e
      Rails.logger.error("[CentralOAuthController#callback] #{e.class}: #{e.message}")
      redirect_to fallback_redirect_path(pending), alert: "OAuth callback failed. Please try again."
    end

    private

    def central_auth_client
      @central_auth_client ||= Auth::CentralOAuthClient.new
    end

    def requested_surface
      surface = params[:surface].to_s
      surface == "admin" ? "admin" : "account"
    end

    def fallback_login_path(surface)
      surface.to_s == "admin" ? admin_login_path : account_login_path
    end

    def resolve_post_login_path(pending)
      if pending["surface"].to_s == "admin"
        return admin_dashboard_path
      end

      account_dashboard_path
    end

    def establish_session_for(user, pending)
      surface = pending["surface"].to_s

      if surface == "admin"
        unless user.admin_account&.active?
          raise "User does not have active admin access"
        end

        reset_session
        session[AppConstants::Sessions.key(:admin)] = user.id
        session[ADMIN_TEMPLE_SESSION_KEY] = default_admin_temple_slug(user)
        return
      end

      temple_slug = pending["temple"].presence
      reset_session
      session[ACCOUNT_TEMPLE_SESSION_KEY] = temple_slug if temple_slug.present?
      session[AppConstants::Sessions.key(:account)] = user.id
    end

    def default_admin_temple_slug(user)
      return nil unless user&.admin_account

      user.admin_account.temples.order(:name).limit(1).pluck(:slug).first
    end

    def resolve_identity_from_exchange!(response, pending, account_user)
      fields = extract_identity_fields(response)
      provider = normalize_identity_provider(fields[:provider])
      uid = fields[:uid]

      if provider.blank?
        Rails.logger.error("[CentralOAuthController#callback] Missing provider in exchange response keys=#{response.keys}")
        raise "OAuth exchange missing provider"
      end

      if uid.blank?
        Rails.logger.error("[CentralOAuthController#callback] Missing uid in exchange response keys=#{response.keys}")
        raise "OAuth exchange missing uid"
      end

      result =
        if link_intent?(pending)
          raise "You must be signed in to link a provider." if account_user.blank?

          Auth::OAuthIdentityLinker.link!(
            user: account_user,
            provider: provider,
            uid: uid,
            email: fields[:email],
            email_verified: fields[:email_verified],
            credentials: response["credentials"] || {},
            metadata: { "central_auth" => response }
          )
        else
          Auth::OAuthIdentityResolver.resolve_or_link!(
            provider: provider,
            uid: uid,
            email: fields[:email],
            name: fields[:name],
            email_verified: fields[:email_verified],
            credentials: response["credentials"] || {},
            metadata: { "central_auth" => response }
          )
        end

      ensure_terms_acceptance(link_intent?(pending) ? account_user : result.user, provider)
      [result.identity, link_intent?(pending) ? account_user : result.user, result]
    end

    def extract_identity_fields(response)
      claims = extract_claims(response)
      id_token_claims = extract_id_token_claims(response)

      {
        provider: first_present(
          claims["provider"],
          response["provider"],
          id_token_claims["provider"],
          response.dig("identity", "provider")
        ),
        uid: first_present(
          claims["provider_uid"],
          claims["uid"],
          claims["sub"],
          claims["subject"],
          response["provider_uid"],
          response["uid"],
          response["sub"],
          response["subject"],
          response.dig("identity", "provider_uid"),
          response.dig("identity", "uid"),
          response.dig("identity", "sub"),
          id_token_claims["sub"],
          id_token_claims["uid"]
        ),
        email: first_present(
          claims["email"],
          response["email"],
          response.dig("identity", "email"),
          response.dig("user", "email"),
          id_token_claims["email"]
        ),
        name: first_present(
          claims["name"],
          response["name"],
          response.dig("identity", "name"),
          response.dig("user", "name"),
          id_token_claims["name"]
        ),
        email_verified: first_present(
          claims["email_verified"],
          response["email_verified"],
          response.dig("identity", "email_verified"),
          response.dig("user", "email_verified"),
          id_token_claims["email_verified"]
        )
      }
    end

    def extract_claims(response)
      value =
        response["claims"] ||
        response["user"] ||
        response["profile"] ||
        response.dig("identity", "claims") ||
        response.dig("credentials", "claims") ||
        {}

      value.is_a?(Hash) ? value : {}
    end

    def extract_id_token_claims(response)
      token =
        response["id_token"] ||
        response.dig("credentials", "id_token") ||
        response.dig("tokens", "id_token")

      return {} if token.blank?

      payload = token.to_s.split(".")[1]
      return {} if payload.blank?

      padded = payload + ("=" * ((4 - payload.length % 4) % 4))
      decoded = Base64.urlsafe_decode64(padded)
      parsed = JSON.parse(decoded)
      parsed.is_a?(Hash) ? parsed : {}
    rescue StandardError
      {}
    end

    def first_present(*values)
      values.find(&:present?)
    end

    def central_tenant_slug(pending)
      ENV["AUTH_TENANT_SLUG"].presence || pending["tenant"].presence
    end

    def normalized_intent(value)
      intent = value.to_s
      intent == "link" ? "link" : nil
    end

    def link_intent?(pending)
      pending["intent"].to_s == "link"
    end

    def current_account_user
      user_id = session[ACCOUNT_SESSION_KEY]
      return nil if user_id.blank?

      User.find_by(id: user_id)
    end

    def oauth_account_linking_enabled_for?(user)
      FeatureFlags::Evaluator.enabled?("oauth_account_linking", actor: user)
    end

    def fallback_redirect_path(pending)
      origin = pending["origin"].to_s
      return origin if origin.start_with?("/")

      fallback_login_path(pending["surface"])
    end

    def success_redirect_path(pending)
      return fallback_redirect_path(pending) if link_intent?(pending)

      resolve_post_login_path(pending)
    end

    def success_notice(pending, link_result, identity)
      return "Signed in successfully." unless link_intent?(pending)
      return "Your #{identity.provider.titleize} account is already linked." if link_result&.respond_to?(:already_linked) && link_result.already_linked

      "Linked #{identity.provider.titleize} to your account."
    end

    def log_oauth_event(action, user:, pending:, provider:, **metadata)
      temple = Temple.find_by(slug: pending["temple"]) if pending["temple"].present?
      actor = user || current_account_user
      return if actor.blank?

      SystemAuditLogger.log!(
        action: action,
        admin: actor,
        target: actor,
        metadata: metadata.merge(provider: provider, surface: pending["surface"], intent: pending["intent"]),
        temple: temple
      )
    end

    def normalize_provider_param(value)
      PROVIDER_ALIASES[value.to_s]
    end

    def normalize_identity_provider(value)
      mapped = PROVIDER_ALIASES[value.to_s]
      PROVIDER_TO_IDENTITY[mapped]
    end

    def ensure_terms_acceptance(user, provider)
      metadata = (user.metadata || {}).with_indifferent_access
      updated_metadata = metadata.merge(
        signup_source: metadata[:signup_source].presence || provider,
        terms_version: metadata[:terms_version].presence || AppConstants::Legal.default_terms_version,
        terms_accepted_at: metadata[:terms_accepted_at].presence || Time.current.iso8601
      )
      return if updated_metadata == metadata

      user.update!(metadata: updated_metadata)
    end
  end
end
