class ClientCacheState < ApplicationRecord
  belongs_to :user
  belongs_to :client_checkin

  validates :state_key, presence: true
  validates :version, numericality: { greater_than_or_equal_to: 0 }

  scope :stale, -> { where(needs_refresh: true) }
end
