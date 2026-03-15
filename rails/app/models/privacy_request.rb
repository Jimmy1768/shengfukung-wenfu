# frozen_string_literal: true

class PrivacyRequest < ApplicationRecord
  REQUEST_TYPES = %w[account_closure data_deletion data_export].freeze
  STATUSES = %w[pending approved completed rejected cancelled].freeze
  SUBMITTED_VIA = %w[web expo operator].freeze

  belongs_to :user
  belongs_to :operator_user, class_name: "User", optional: true

  validates :request_type, inclusion: { in: REQUEST_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :submitted_via, inclusion: { in: SUBMITTED_VIA }
  validates :requested_at, presence: true

  scope :open_requests, -> { where(status: %w[pending approved]) }
end
