# config/initializers/jwt.rb
#
# Global JWT configuration for the Golden Template.
#
# This file:
# - reads secrets and settings from ENV
# - defines Auth::JwtConfig module with constants
# - must NOT contain business logic or DB access
#
# Actual token encoding/decoding lives in:
#   app/services/auth/jwt_service.rb
#
# Refresh token lifecycle lives in:
#   app/services/auth/refresh_token_service.rb
#

module Auth
  module JwtConfig
    # === Secret & Algorithm ================================================
    #
    # IMPORTANT:
    # - In production, JWT_SECRET_KEY MUST be set.
    # - In development, we allow a fallback so you can get started quickly.
    #

    SECRET = ENV["JWT_SECRET_KEY"]

    if Rails.env.production? && SECRET.blank?
      raise "Missing JWT_SECRET_KEY in production"
    end

    # Fallback dev secret (safe to use only in non-production).
    DEFAULT_DEV_SECRET = "dev-jwt-secret-change-me".freeze

    EFFECTIVE_SECRET =
      if SECRET.present?
        SECRET
      else
        DEFAULT_DEV_SECRET
      end

    ALGORITHM = ENV.fetch("JWT_ALGORITHM", "HS256").freeze

    # === Token Lifetimes (in seconds) ======================================
    #
    # Access tokens: short-lived (e.g. 15 minutes)
    # Refresh tokens: long-lived (e.g. 30 days)
    #
    # You can override via ENV if needed:
    #   JWT_ACCESS_TTL (seconds)
    #   JWT_REFRESH_TTL (seconds)
    #

    DEFAULT_ACCESS_TTL  = 15 * 60        # 15 minutes
    DEFAULT_REFRESH_TTL = 30 * 24 * 3600 # 30 days

    ACCESS_TOKEN_TTL  = (ENV["JWT_ACCESS_TTL"]  || DEFAULT_ACCESS_TTL).to_i
    REFRESH_TOKEN_TTL = (ENV["JWT_REFRESH_TTL"] || DEFAULT_REFRESH_TTL).to_i

    # === Issuer / Leeway ===================================================
    #
    # Issuer helps prevent cross-app token reuse.
    # Leeway accounts for small clock drift between machines.
    #

    ISSUER = ENV.fetch("JWT_ISSUER", "golden-template-api").freeze
    LEEWAY = (ENV["JWT_LEEWAY"] || 30).to_i
  end
end

if Rails.env.development?
  if Auth::JwtConfig::SECRET.blank?
    Rails.logger.warn "[JWT] Using DEFAULT_DEV_SECRET. Set JWT_SECRET_KEY for stronger security."
  else
    Rails.logger.info "[JWT] JWT_SECRET_KEY present."
  end
end

require Rails.root.join("app/services/auth/jwt_service")
