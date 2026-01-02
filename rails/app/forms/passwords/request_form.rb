# frozen_string_literal: true

module Passwords
  class RequestForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :email, :string

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

    def submit
      return false unless valid?

      user = User.find_by(email: normalized_email)
      if block_given? && user.present?
        token = Auth::PasswordReset.request_reset_for(user)
        yield(user, token) if token.present?
      end

      true
    rescue StandardError => e
      Rails.logger.error "[Passwords::RequestForm] Failed to issue reset token: #{e.class}: #{e.message}"
      errors.add(:base, I18n.t("account.passwords.errors.unknown"))
      false
    end

    def normalized_email
      email.to_s.downcase.strip
    end
  end
end
