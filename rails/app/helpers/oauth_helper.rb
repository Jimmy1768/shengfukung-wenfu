module OAuthHelper
  PROVIDER_SPECS = {
    google: { label: "Continue with Google", icon_path: "/icons/google.png" },
    apple: { label: "Continue with Apple", icon_path: "/icons/apple.png" },
    facebook: { label: "Continue with Facebook", icon_path: "/icons/facebook.png" }
  }.freeze

  def oauth_provider_links
    PROVIDER_SPECS.filter_map do |key, payload|
      strategy = AppConstants::OAuth::PROVIDERS[key][:strategy] || key

      if AppConstants::OAuth.central_auth_enabled?
        {
          label: payload[:label],
          strategy: strategy,
          icon_path: payload[:icon_path],
          path: central_oauth_start_path(
            provider: key,
            surface: oauth_surface,
            temple: params[:temple].presence,
            origin: request.fullpath
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

  private

  def oauth_surface
    request.path.start_with?("/admin") ? "admin" : "account"
  end
end
