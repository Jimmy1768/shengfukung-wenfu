module Auth
  class OmniauthController < ActionController::Base
    protect_from_forgery with: :exception
    skip_before_action :verify_authenticity_token

    def callback
      auth_hash = request.env["omniauth.auth"]
      identity = find_or_create_identity(auth_hash)
      raise "Closed account cannot sign in" if identity.user.closed_account?

      establish_account_session!(identity.user)

      if respond_with_json?
        render json: { provider: identity.provider, user_id: identity.user_id }
      else
        redirect_to oauth_redirect_path, notice: "Signed in with #{identity.provider.titleize}."
      end
    rescue StandardError => e
      Rails.logger.error("[OmniauthController] #{e.class}: #{e.message}")
      message = e.message == "Closed account cannot sign in" ? I18n.t("account.sessions.flash.account_closed") : "OAuth login failed. Please try again."
      if respond_with_json?
        render json: { error: message }, status: :unprocessable_content
      else
        redirect_to account_login_path, alert: message
      end
    end

    def failure
      message = params[:message] || "OAuth failure"
      if respond_with_json?
        render json: { error: message }, status: :unauthorized
      else
        redirect_to account_login_path, alert: message
      end
    end

    private

    def respond_with_json?
      request.format.json?
    end

    def oauth_redirect_path
      request.env["omniauth.origin"].presence || account_dashboard_path
    end

    def establish_account_session!(user)
      reset_session
      session[AppConstants::Sessions.key(:account)] = user.id
    end

    def find_or_create_identity(auth_hash)
      provider = auth_hash["provider"].to_s
      uid = auth_hash["uid"].to_s

      result = Auth::OAuthIdentityResolver.resolve_or_link!(
        provider: provider,
        uid: uid,
        email: auth_hash.dig("info", "email"),
        name: auth_hash.dig("info", "name"),
        email_verified: auth_hash.dig("info", "email_verified"),
        credentials: auth_hash["credentials"] || {},
        metadata: {
          "info" => auth_hash["info"],
          "extra" => auth_hash["extra"]
        }
      )

      ensure_terms_acceptance(result.user, provider)
      result.identity
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
