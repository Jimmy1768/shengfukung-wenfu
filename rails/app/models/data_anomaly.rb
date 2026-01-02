class DataAnomaly < ApplicationRecord
  belongs_to :record, polymorphic: true, optional: true

  STATUSES = %w[open investigating resolved closed].freeze

  validates :detector_key, :severity, :status, :detected_at, presence: true
  validates :status, inclusion: { in: STATUSES }
end
