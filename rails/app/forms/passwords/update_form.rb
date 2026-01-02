# frozen_string_literal: true

module Passwords
  class UpdateForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :token, :string
    attribute :password, :string
    attribute :password_confirmation, :string

    validates :token, presence: true
    validates :password, presence: true, confirmation: true, length: { minimum: 8 }
    validates :password_confirmation, presence: true

    def submit
      return false unless valid?

      result = Auth::PasswordReset.reset_password(token, password)
      return true if result.success?

      errors.add(:base, error_message_for(result.error))
      false
    end

    private

    def error_message_for(code)
      I18n.t("account.passwords.errors.#{code || :unknown}", default: "Unable to reset password.")
    end
  end
end
