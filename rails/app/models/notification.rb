class Notification < ApplicationRecord
  STATUSES = %w[pending scheduled sending sent failed cancelled].freeze

  belongs_to :notification_rule, optional: true
  belongs_to :user, optional: true

  validates :channel, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
end
