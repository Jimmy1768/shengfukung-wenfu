# frozen_string_literal: true

class TemplePayment < ApplicationRecord
  PAYMENT_METHODS = {
    cash: "cash",
    line_pay: "line_pay",
    stripe: "stripe"
  }.freeze

  STATUSES = {
    pending: "pending",
    completed: "completed",
    failed: "failed",
    refunded: "refunded"
  }.freeze

  belongs_to :temple
  belongs_to :temple_event_registration
  belongs_to :user, optional: true
  belongs_to :financial_ledger_entry, optional: true
  belongs_to :admin_account, optional: true

  delegate :temple_offering, to: :temple_event_registration

  validates :payment_method, inclusion: { in: PAYMENT_METHODS.values }
  validates :status, inclusion: { in: STATUSES.values }
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true

  scope :completed, -> { where(status: STATUSES[:completed]) }

  def cash?
    payment_method == PAYMENT_METHODS[:cash]
  end
end
