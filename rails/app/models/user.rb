# frozen_string_literal: true

require "digest"

class User < ApplicationRecord
  has_one :admin_account,
    class_name: "AdminAccount",
    dependent: :destroy,
    inverse_of: :user
  has_one :user_preference, dependent: :destroy
  has_many :user_dependents, dependent: :destroy
  has_many :dependents, through: :user_dependents
  has_many :oauth_identities, dependent: :destroy
  has_many :temple_event_registrations, dependent: :nullify
  has_many :temple_payments, dependent: :nullify

  validates :email, presence: true, uniqueness: true
  validate :at_least_one_name_present

  before_validation :normalize_email

  def self.password_hash(plain_text)
    Digest::SHA256.hexdigest(plain_text.to_s)
  end

  def seeded_metadata
    {
      seeded_at: Time.current.iso8601,
      seeded_by: "db:seed:admin_controls"
    }
  end

  alias_method :admin, :admin_account
  alias_method :admin=, :admin_account=

  private

  def normalize_email
    return unless email.present?

    self.email = email.downcase.strip
  end

  def admin?
    admin_account&.active?
  end

  def at_least_one_name_present
    return if english_name.to_s.strip.present? || native_name.to_s.strip.present?

    errors.add(:base, I18n.t("account.profile.edit.errors.name_required"))
  end
end
