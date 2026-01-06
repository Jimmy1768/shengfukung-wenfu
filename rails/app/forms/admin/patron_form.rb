# frozen_string_literal: true

require "uri"

module Admin
  class PatronForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :english_name, :string
    attribute :email, :string
    attribute :phone, :string
    attribute :notes, :string

    validates :english_name, presence: true
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validate :email_not_taken

    attr_reader :user

    def save
      return false unless valid?

      @user = User.create!(
        english_name: english_name.strip,
        email: normalized_email,
        encrypted_password: User.password_hash(SecureRandom.hex(10)),
        metadata: metadata_payload
      )
      true
    rescue ActiveRecord::RecordInvalid => e
      errors.merge!(e.record.errors)
      false
    end

    private

    def normalized_email
      email.to_s.downcase.strip
    end

    def metadata_payload
      meta = {}
      meta["phone"] = phone if phone.present?
      meta["notes"] = notes if notes.present?
      meta
    end

    def email_not_taken
      return if normalized_email.blank?
      return unless User.exists?(email: normalized_email)

      errors.add(:email, "has already been taken")
    end
  end
end
