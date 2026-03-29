# config/initializers/cors.rb
#
# CORS configuration for the Golden Template.
#
# Principle:
# - Allow specific trusted domains only (from ENV).
# - In development: allow localhost ports for Rails, Vite/Vue, Expo tunnels.
# - In production: allow only domains explicitly provided in ENV.
#
# IMPORTANT:
# CORS should whitelist front-end *hosts* only.
# Endpoints themselves still require authentication (JWT/cookie/etc.).
#

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # ------------------------------------------------------------------
    # Build a list of origins allowed to talk to the API server.
    # ------------------------------------------------------------------
    allowed_origins = []

    # Development and production ports differ:
    # - Production: 3000
    # - Development: 3002

    if Rails.env.development?
      # Rails UI (dev mode)
      allowed_origins << "http://localhost:3002"
      allowed_origins << "http://127.0.0.1:3002"

      # Legacy local Rails port kept for compatibility during the transition.
      allowed_origins << "http://localhost:3001"
      allowed_origins << "http://127.0.0.1:3001"

      # Vite / Vue dev server (unchanged)
      allowed_origins << "http://localhost:5173"
      allowed_origins << "http://127.0.0.1:5173"

      # Expo tunnel domains
      allowed_origins << /\Ahttps?:\/\/.*\.expo\.dev\z/
    else
      # Production Rails UI
      allowed_origins << "http://localhost:3000"   # fallback for internal tools
      allowed_origins << "http://127.0.0.1:3000"

      # Better: use ENV-based production domains
      %w[WEB_DOMAIN APP_DOMAIN DEV_DOMAIN].each do |key|
        host = ENV[key]
        allowed_origins << "https://#{host}" if host.present?
      end
    end

    # ------------------------------------------------------------------
    # Final CORS rule
    # ------------------------------------------------------------------
    origins allowed_origins

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
