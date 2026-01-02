require "omniauth"
require Rails.root.join("app", "lib", "app_constants", "oauth").to_s

OmniAuth.config.logger = Rails.logger
OmniAuth.config.allowed_request_methods = %i[get post]

Rails.application.config.middleware.use OmniAuth::Builder do
  AppConstants::OAuth.enabled_providers.each do |provider, client_id, client_secret, scope|
    provider(provider, client_id, client_secret, scope: scope, access_type: "offline")
  end
end
