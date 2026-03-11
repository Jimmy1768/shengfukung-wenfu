module OAuthHelper
  PROVIDER_SPECS = {
    google: { label: "Continue with Google", icon_path: "/backend/assets/icons/google.png" },
    apple: { label: "Continue with Apple", icon_path: "/backend/assets/icons/apple.png" },
    facebook: { label: "Continue with Facebook", icon_path: "/backend/assets/icons/facebook.png" }
  }.freeze

  def oauth_provider_links
    PROVIDER_SPECS.filter_map do |key, payload|
      strategy = AppConstants::OAuth::PROVIDERS[key][:strategy] || key

      if AppConstants::OAuth.central_auth_enabled?
        after_sign_in = params[:after_sign_in].presence || @after_sign_in.presence
        {
          label: payload[:label],
          strategy: strategy,
          icon_path: payload[:icon_path],
          path: central_oauth_start_path(
            provider: key,
            surface: oauth_surface,
            temple: params[:temple].presence,
            origin: request.fullpath,
            after_sign_in: after_sign_in
          )
        }
      else
        next unless AppConstants::OAuth.enabled?(key)

        {
          label: payload[:label],
          strategy: strategy,
          icon_path: payload[:icon_path],
          path: "/auth/#{strategy}"
        }
      end
    end
  end

  def oauth_provider_label(provider)
    PROVIDER_SPECS.each do |key, payload|
      strategy = (AppConstants::OAuth::PROVIDERS[key][:strategy] || key).to_s
      return payload[:label].sub(/\AContinue with /, "") if provider.to_s == strategy
    end

    provider.to_s.humanize
  end

  private

  def oauth_surface
    request.path.start_with?("/admin") ? "admin" : "account"
  end
end
