# frozen_string_literal: true

class OAuthIdentity < ApplicationRecord
  PROVIDERS = %w[google_oauth2 apple facebook email].freeze

  belongs_to :user

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :provider_uid, presence: true
  validates :user_id, uniqueness: { scope: :provider, message: "already linked to this provider" }
  validates :provider_uid, uniqueness: { scope: :provider }
  validates :email_verified, inclusion: { in: [true, false] }, allow_nil: true

  scope :for_provider, ->(provider) { where(provider: provider) }
  scope :recently_active, -> { order(last_login_at: :desc, updated_at: :desc) }
end
