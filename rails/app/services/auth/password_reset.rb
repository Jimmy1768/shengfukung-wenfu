
# app/services/auth/password_reset.rb
#
# Helper for issuing and consuming password reset tokens.
# Typically works together with:
# - PasswordsController
# - PasswordMailer
#
require "digest"

module Auth
  class PasswordReset
    TOKEN_TTL = 2.hours
    TOKEN_LENGTH = 48

    Result = Struct.new(:success?, :user, :error, keyword_init: true)

    class << self
      # Issues (or refreshes) a password reset token and returns the raw token.
      # The caller is responsible for delivering the email.
      def request_reset_for(user)
        return if user.blank?

        raw_token = Util::Slugger.random_token(length: TOKEN_LENGTH)
        digest = digest_token(raw_token)

        user.update!(
          password_reset_token: digest,
          password_reset_sent_at: Time.current
        )

        raw_token
      end

      # Verifies a reset token and returns the associated user if valid.
      def verify_token(raw_token)
        return nil if raw_token.blank?

        digest = digest_token(raw_token)
        user = User.find_by(password_reset_token: digest)
        return nil unless user
        return nil if token_expired?(user)

        user
      end

      # Applies a new password for the user given a valid token.
      def reset_password(raw_token, new_password)
        user = verify_token(raw_token)
        return Result.new(success?: false, error: :invalid_token) unless user
        return Result.new(success?: false, error: :invalid_password) if new_password.to_s.length < 8

        hashed_password = User.password_hash(new_password)
        if user.update(
            encrypted_password: hashed_password,
            password_reset_token: nil,
            password_reset_sent_at: nil
          )
          Result.new(success?: true, user: user)
        else
          Result.new(success?: false, user: user, error: :update_failed)
        end
      end

      private

      def digest_token(raw_token)
        Digest::SHA256.hexdigest(raw_token.to_s)
      end

      def token_expired?(user)
        sent_at = user.password_reset_sent_at
        return true if sent_at.blank?

        sent_at < TOKEN_TTL.ago
      end
    end
  end
end
