class DataExportPayload < ApplicationRecord
  belongs_to :data_export_job

  validates :storage_location, :available_at, presence: true
end
