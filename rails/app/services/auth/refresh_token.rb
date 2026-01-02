# app/services/auth/refresh_token.rb
#
# Auth::RefreshToken
# ------------------------------------------------------------------
# Placeholder for DB-backed refresh token lifecycle.
#
# Responsibilities (once models/migrations exist):
# - Issue refresh tokens (and store hashed versions in DB)
# - Rotate refresh tokens (invalidate old, create new)
# - Revoke tokens per device
# - "Sign out of all devices" for a user
#
# IMPORTANT:
# - This is a sketch for Golden Template.
# - It assumes a future RefreshToken model (not created yet).
# - Do NOT add migrations here; keep schema work separate.
#

module Auth
  class RefreshToken
    # Usage idea:
    #
    #   service = Auth::RefreshToken.new(user)
    #   raw_refresh_token = service.issue!(user_agent: ua, ip_address: ip)
    #
    #   # later, to rotate:
    #   new_raw_token = service.rotate!(old_raw_refresh_token)
    #
    #   # sign out all devices:
    #   service.revoke_all!
    #

    def initialize(user)
      @user = user
    end

    # Issue a new refresh token for this user.
    # Returns the *raw* token string to send to the client.
    #
    # Later, you will:
    # - generate a secure random token
    # - store a hashed version in the database (e.g. RefreshToken model)
    # - set an expires_at using Auth::JwtConfig::REFRESH_TOKEN_TTL
    #
    def issue!(user_agent: nil, ip_address: nil, context: nil)
      # Placeholder implementation.
      #
      # Example real logic (later, once you have a model):
      #   raw_token = SecureRandom.hex(32)
      #   RefreshToken.create!(
      #     user: @user,
      #     token_digest: Digest::SHA256.hexdigest(raw_token),
      #     user_agent: user_agent,
      #     ip_address: ip_address,
      #     context: context,
      #     expires_at: Time.current + Auth::JwtConfig::REFRESH_TOKEN_TTL
      #   )
      #   raw_token
      #
      raise NotImplementedError, "RefreshToken#issue! is a sketch; implement with your RefreshToken model."
    end

    # Rotate an existing refresh token and return a new raw token.
    #
    # Expected behavior (later):
    # - find the existing RefreshToken by digest
    # - ensure not expired / revoked
    # - delete or mark old token as used
    # - create a new token row and return the raw token
    #
    def rotate!(raw_token)
      # Placeholder.
      raise NotImplementedError, "RefreshToken#rotate! is a sketch; implement rotation with your RefreshToken model."
    end

    # Revoke all refresh tokens for this user.
    # Used for "sign out of all devices/webapps".
    #
    def revoke_all!
      # Placeholder.
      #
      # Example later:
      #   RefreshToken.where(user: @user).delete_all
      #
      raise NotImplementedError, "RefreshToken#revoke_all! is a sketch; implement revocation logic."
    end
  end
end
