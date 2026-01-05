# frozen_string_literal: true

class LinePayCallback < ApplicationRecord
  belongs_to :temple

  validates :line_pay_transaction_id, presence: true
  validates :payload, presence: true

  scope :pending_process, -> { where(processed: false) }
end
