# app/services/auth/jwt_service.rb
#
# Auth::JwtService
# ------------------------------------------------------------------
# Stateless JWT encoder/decoder.
#
# Responsibilities:
# - Encode a payload into a signed JWT
# - Decode and verify a JWT, returning payload or nil
#
# This service:
# - Does NOT touch the database
# - Does NOT manage refresh tokens
# - Uses Auth::JwtConfig for all settings
#
# Usage (example):
#
#   token = Auth::JwtService.encode({ user_id: user.id })
#   payload = Auth::JwtService.decode(token)
#
require "jwt"

module Auth
  class JwtService
    def self.encode(payload, expires_in: nil)
      new.encode(payload, expires_in: expires_in)
    end

    def self.decode(token)
      new.decode(token)
    end

    def initialize(config = JwtConfig)
      @config = config
    end

    # Encode a JWT with exp + iss claims
    def encode(payload, expires_in: nil)
      ttl = (expires_in || @config::ACCESS_TOKEN_TTL).to_i
      exp = Time.now.to_i + ttl

      full_payload = payload.merge(
        "exp" => exp,
        "iss" => @config::ISSUER
      )

      JWT.encode(
        full_payload,
        @config::EFFECTIVE_SECRET,
        @config::ALGORITHM
      )
    end

    # Decode and verify a JWT.
    # Returns the payload as a hash with string keys, or nil on failure.
    def decode(token)
      options = {
        algorithm:   @config::ALGORITHM,
        iss:         @config::ISSUER,
        verify_iss:  true,
        leeway:      @config::LEEWAY
        # JWT gem will verify 'exp' by default if present
      }

      decoded, _header = JWT.decode(
        token,
        @config::EFFECTIVE_SECRET,
        true,   # verify signature
        options
      )

      decoded # can wrap with indifferent_access if you like
    rescue JWT::ExpiredSignature
      Rails.logger.info "[Auth::JwtService] token expired"
      nil
    rescue JWT::DecodeError => e
      Rails.logger.info "[Auth::JwtService] decode failed: #{e.class}: #{e.message}"
      nil
    end
  end
end
