# frozen_string_literal: true

require "digest"

class User < ApplicationRecord
  ACCOUNT_STATUSES = %w[active closed].freeze
  CLOSURE_REASONS = %w[self_service operator_action privacy_request].freeze

  has_one :admin_account,
    class_name: "AdminAccount",
    dependent: :destroy,
    inverse_of: :user
  has_one :user_preference, dependent: :destroy
  has_one :privacy_setting, dependent: :destroy
  has_many :user_dependents, dependent: :destroy
  has_many :dependents, through: :user_dependents
  has_many :oauth_identities, dependent: :destroy
  has_many :refresh_tokens, dependent: :destroy
  has_many :push_tokens, dependent: :destroy
  has_many :privacy_requests, dependent: :destroy
  has_many :account_lifecycle_events, dependent: :destroy
  has_many :temple_event_registrations, dependent: :nullify
  has_many :temple_payments, dependent: :nullify
  belongs_to :closed_by_user, class_name: "User", optional: true

  validates :email, presence: true, uniqueness: true
  validates :account_status, inclusion: { in: ACCOUNT_STATUSES }
  validates :closure_reason, inclusion: { in: CLOSURE_REASONS }, allow_blank: true
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

  def active_account?
    account_status == "active"
  end

  def closed_account?
    account_status == "closed"
  end

  def close_account!(reason:, closed_by: self)
    reason = reason.to_s
    raise ArgumentError, "invalid closure reason" unless CLOSURE_REASONS.include?(reason)

    transaction do
      update!(
        account_status: "closed",
        closed_at: Time.current,
        closure_reason: reason,
        closed_by_user: closed_by
      )

      refresh_tokens.update_all(revoked: true, updated_at: Time.current)
      push_tokens.update_all(active: false, updated_at: Time.current)
      oauth_identities.find_each do |identity|
        metadata = identity.metadata.is_a?(Hash) ? identity.metadata : {}
        identity.update!(
          metadata: metadata.merge(
            "revoked_at" => Time.current.iso8601,
            "revoked_reason" => reason
          )
        )
      end

      account_lifecycle_events.create!(
        event_type: "account_closed",
        occurred_at: Time.current,
        user_name_snapshot: native_name.presence || english_name.presence || email,
        metadata: {
          "reason" => reason,
          "closed_by_user_id" => closed_by&.id
        }
      )
    end
  end

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
