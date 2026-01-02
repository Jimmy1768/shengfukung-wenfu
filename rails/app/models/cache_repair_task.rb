class CacheRepairTask < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :client_checkin, optional: true

  STATUSES = %w[pending running succeeded failed].freeze

  validates :repair_key, presence: true
  validates :status, inclusion: { in: STATUSES }
end
