class BackgroundTask < ApplicationRecord
  STATUSES = %w[pending queued running succeeded failed cancelled].freeze

  validates :task_key, presence: true
  validates :status, inclusion: { in: STATUSES }
end
