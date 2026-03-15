# frozen_string_literal: true

class TempleAssistanceRequest < ApplicationRecord
  STATUSES = %w[open closed].freeze
  CHANNELS = %w[profile registration_list registration_detail].freeze

  belongs_to :temple
  belongs_to :user
  belongs_to :temple_registration, class_name: "TempleRegistration", optional: true
  belongs_to :closed_by_admin, class_name: "AdminAccount", optional: true

  validates :status, inclusion: { in: STATUSES }
  validates :channel, inclusion: { in: CHANNELS }
  validates :requested_at, presence: true
  validates :message, length: { maximum: 280 }, allow_blank: true

  scope :open_requests, -> { where(status: "open") }
  scope :recent_first, -> { order(requested_at: :desc, created_at: :desc) }

  def self.find_open_for(temple:, user:, temple_registration: nil)
    where(
      temple:,
      user:,
      temple_registration:,
      status: "open"
    ).order(requested_at: :desc, created_at: :desc).first
  end

  def closed?
    status == "closed"
  end

  def close!(admin_account:)
    update!(
      status: "closed",
      closed_at: Time.current,
      closed_by_admin: admin_account
    )
  end

  def display_message
    message.presence
  end
end
