# frozen_string_literal: true

module Account
  class PasswordSettingsForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :password, :string
    attribute :password_confirmation, :string

    attr_reader :user

    validates :password, presence: true, confirmation: true, length: { minimum: 8 }
    validates :password_confirmation, presence: true
    validate :user_present
    validate :password_not_already_enabled

    def initialize(user:, params: nil)
      @user = user
      super(params || {})
    end

    def save
      return false unless valid?

      updated_metadata = user.metadata.is_a?(Hash) ? user.metadata.deep_dup : {}
      updated_metadata["oauth_seeded"] = false

      user.update(
        encrypted_password: User.password_hash(password),
        metadata: updated_metadata
      )
    end

    def password_enabled?
      user&.encrypted_password.present? && !oauth_seeded_user?
    end

    private

    def user_present
      errors.add(:base, I18n.t("account.settings.errors.unknown")) if user.blank?
    end

    def password_not_already_enabled
      return if user.blank? || !password_enabled?

      errors.add(:base, I18n.t("account.settings.errors.already_enabled"))
    end

    def oauth_seeded_user?
      return false if user.blank?

      metadata = user.metadata.is_a?(Hash) ? user.metadata : {}
      ActiveModel::Type::Boolean.new.cast(metadata["oauth_seeded"] || metadata[:oauth_seeded])
    end
  end
end
