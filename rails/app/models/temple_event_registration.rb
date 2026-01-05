# frozen_string_literal: true

class TempleEventRegistration < ApplicationRecord
  PAYMENT_STATUSES = {
    pending: "pending",
    paid: "paid",
    refunded: "refunded",
    failed: "failed"
  }.freeze
  FULFILLMENT_STATUSES = {
    open: "open",
    fulfilled: "fulfilled",
    cancelled: "cancelled"
  }.freeze

  belongs_to :temple
  belongs_to :temple_offering, optional: true
  belongs_to :user, optional: true

  has_many :temple_payments, dependent: :destroy

  validates :reference_code, presence: true, uniqueness: { scope: :temple_id }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES.values }
  validates :fulfillment_status, inclusion: { in: FULFILLMENT_STATUSES.values }
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price_cents, :total_price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true

  before_validation :assign_reference_code
  before_validation :backfill_currency
  before_validation :calculate_totals

  scope :recent, -> { order(created_at: :desc) }
  scope :with_status, ->(status) { where(payment_status: status) }

  def paid?
    payment_status == PAYMENT_STATUSES[:paid]
  end

  def mark_paid!
    update!(payment_status: PAYMENT_STATUSES[:paid])
  end

  private

  def assign_reference_code
    self.reference_code ||= "REG-#{SecureRandom.hex(4).upcase}"
  end

  def backfill_currency
    self.currency ||= temple_offering&.currency || "TWD"
  end

  def calculate_totals
    self.unit_price_cents = temple_offering&.price_cents if unit_price_cents.to_i.zero? && temple_offering.present?
    self.total_price_cents = unit_price_cents.to_i * quantity.to_i
  end
end
