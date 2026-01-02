module OAuthHelper
  PROVIDER_SPECS = {
    google: { label: "Continue with Google", icon_path: "/icons/google.png" },
    apple: { label: "Continue with Apple", icon_path: "/icons/apple.png" },
    facebook: { label: "Continue with Facebook", icon_path: "/icons/facebook.png" }
  }.freeze

  def oauth_provider_links
    PROVIDER_SPECS.filter_map do |key, payload|
      next unless AppConstants::OAuth.enabled?(key)

      strategy = AppConstants::OAuth::PROVIDERS[key][:strategy] || key
      {
        label: payload[:label],
        strategy: strategy,
        icon_path: payload[:icon_path]
      }
    end
  end
end
