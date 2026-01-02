class DataExportJob < ApplicationRecord
  has_many :data_export_payloads, dependent: :destroy

  STATUSES = %w[pending queued running succeeded failed].freeze

  validates :export_key, presence: true
  validates :status, inclusion: { in: STATUSES }
end
