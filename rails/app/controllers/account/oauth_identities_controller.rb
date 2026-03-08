# frozen_string_literal: true

module Account
  class OAuthIdentitiesController < BaseController
    before_action :set_provider_key, only: %i[create destroy]
    before_action :require_oauth_account_linking_enabled!

    def index
      @linked_identities = current_user.oauth_identities.recently_active
      @available_provider_keys = OAuthHelper::PROVIDER_SPECS.keys
    end

    def create
      unless AppConstants::OAuth.central_auth_enabled?
        return redirect_to account_oauth_identities_path, alert: t("account.oauth.flash.unavailable")
      end

      log_oauth_event("account.oauth.link_started", provider: identity_provider)

      redirect_to central_oauth_start_path(
        provider: @provider_key,
        surface: "account",
        temple: active_temple_slug,
        origin: account_oauth_identities_path,
        intent: "link"
      )
    end

    def destroy
      identity = Auth::OAuthIdentityUnlinker.unlink!(user: current_user, provider: identity_provider)
      log_oauth_event("account.oauth.unlinked", provider: identity.provider, identity_id: identity.id)
      redirect_to account_oauth_identities_path, notice: t("account.oauth.flash.unlinked", provider: provider_label)
    rescue Auth::OAuthIdentityUnlinker::LastLoginMethodError, Auth::OAuthIdentityUnlinker::NotLinkedError => e
      redirect_to account_oauth_identities_path, alert: e.message
    end

    private

    def set_provider_key
      @provider_key = params[:provider].to_s
      return if OAuthHelper::PROVIDER_SPECS.key?(@provider_key.to_sym)

      raise ActionController::RoutingError, "Not Found"
    end

    def identity_provider
      AppConstants::OAuth::PROVIDERS.fetch(@provider_key.to_sym).fetch(:strategy).to_s
    end

    def provider_label
      OAuthHelper::PROVIDER_SPECS.fetch(@provider_key.to_sym).fetch(:label).sub(/\AContinue with /, "")
    end

    def require_oauth_account_linking_enabled!
      return if oauth_account_linking_enabled?

      redirect_to account_profile_path, alert: t("account.oauth.flash.disabled")
    end

    def log_oauth_event(action, metadata = {})
      SystemAuditLogger.log!(
        action: action,
        admin: current_user,
        target: current_user,
        metadata: metadata,
        temple: current_temple
      )
    end
  end
end
