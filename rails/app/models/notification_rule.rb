class NotificationRule < ApplicationRecord
  CHANNELS = %w[email push sms webhook].freeze

  validates :event_key, :channel, presence: true
  validates :channel, inclusion: { in: CHANNELS }
end
