class DataTransferLog < ApplicationRecord
  DIRECTIONS = %w[upload download].freeze

  belongs_to :user, optional: true
  belongs_to :client_checkin, optional: true

  validates :direction, inclusion: { in: DIRECTIONS }
  validates :bytes_transferred, numericality: { greater_than_or_equal_to: 0 }
end
