# frozen_string_literal: true

module Account
  class RegistrationForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :email, :string
    attribute :password, :string
    attribute :password_confirmation, :string

    attr_reader :user, :existing_user, :existing_oauth_providers

    validates :email, presence: true
    validates :password, presence: true, confirmation: true, length: { minimum: 8 }
    validates :password_confirmation, presence: true
    validate :email_available

    def save
      return false unless valid?

      @user = User.new(
        email: normalized_email,
        english_name: derived_name,
        encrypted_password: User.password_hash(password),
        metadata: merged_metadata
      )

      @user.save
    end

    private

    def normalized_email
      email.to_s.downcase.strip
    end

    def email_available
      return if normalized_email.blank?
      return unless (@existing_user = User.find_by(email: normalized_email))

      @existing_oauth_providers =
        @existing_user.oauth_identities
          .where.not(provider: "email")
          .distinct
          .pluck(:provider)

      errors.add(:base, I18n.t("account.signups.form.existing_account_guidance"))
    end

    def derived_name
      local_part = normalized_email.split("@").first
      return "New Member" if local_part.blank?

      local_part.tr(".-_", " ").split.map(&:capitalize).join(" ")
    end

    def merged_metadata
      {
        signup_source: "email",
        terms_version: AppConstants::Legal.default_terms_version,
        terms_accepted_at: Time.current.iso8601
      }
    end
  end
end
