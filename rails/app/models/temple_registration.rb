# frozen_string_literal: true

class TempleRegistration < ApplicationRecord
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
  belongs_to :registrable, polymorphic: true
  belongs_to :user, optional: true

  has_many :temple_payments,
    foreign_key: :temple_registration_id,
    dependent: :destroy

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

  def self.admin_filtered(filters)
    filters ||= {}
    scope = includes(:user, :registrable, :temple_payments)
    if filters[:offering_id].present? && filters[:offering_type].present?
      scope = scope.where(
        registrable_id: filters[:offering_id],
        registrable_type: offering_type_filter_values(filters[:offering_type])
      )
    end
    if filters[:payment_method].present?
      scope = scope.left_outer_joins(:temple_payments).where(temple_payments: { payment_method: filters[:payment_method] })
    end
    case filters[:status]
    when PAYMENT_STATUSES[:paid]
      scope = scope.where(payment_status: PAYMENT_STATUSES[:paid])
    when "unpaid"
      scope = scope.where.not(payment_status: PAYMENT_STATUSES[:paid])
    end
    if filters[:query].present?
      sanitized = ActiveRecord::Base.sanitize_sql_like(filters[:query])
      scope = scope.left_outer_joins(:user).where(
        "#{table_name}.reference_code ILIKE :query OR users.english_name ILIKE :query OR users.email ILIKE :query OR (#{table_name}.contact_payload ->> 'name') ILIKE :query",
        query: "%#{sanitized}%"
      )
    end
    if (start_at = parse_admin_filter_date(filters[:start_date]))
      scope = scope.where(arel_table[:created_at].gteq(start_at))
    end
    if (end_at = parse_admin_filter_date(filters[:end_date], end_of_day: true))
      scope = scope.where(arel_table[:created_at].lteq(end_at))
    end
    scope.distinct
  end

  def paid?
    payment_status == PAYMENT_STATUSES[:paid]
  end

  def mark_paid!
    update!(payment_status: PAYMENT_STATUSES[:paid])
  end

  def certificate_number
    metadata_value("certificate_number")
  end

  def certificate_number=(value)
    write_metadata_value("certificate_number", value.presence)
  end

  def event_slug
    metadata_value("event_slug")
  end

  def event_slug=(value)
    write_metadata_value("event_slug", value.presence)
  end

  def temple_offering
    registrable.is_a?(TempleEvent) ? registrable : nil
  end

  def temple_service
    registrable.is_a?(TempleService) ? registrable : nil
  end

  def offering
    registrable
  end

  private

  def assign_reference_code
    self.reference_code ||= "REG-#{SecureRandom.hex(4).upcase}"
  end

  def backfill_currency
    self.currency ||= registrable&.currency || "TWD"
  end

  def calculate_totals
    if unit_price_cents.to_i.zero? && registrable.present?
      self.unit_price_cents = registrable.price_cents
    end
    self.total_price_cents = unit_price_cents.to_i * quantity.to_i
  end

  def self.offering_type_filter_values(type)
    normalized = type.to_s
    case normalized
    when TempleService.name
      [TempleService.name]
    when TempleEvent.name, TempleOffering.name
      [TempleEvent.name, TempleOffering.name]
    when TempleGathering.name
      [TempleGathering.name]
    else
      [normalized.presence].compact
    end
  end

  def self.parse_admin_filter_date(value, end_of_day: false)
    return nil if value.blank?

    timestamp = Time.zone.parse(value.to_s)
    return nil unless timestamp

    end_of_day ? timestamp.end_of_day : timestamp.beginning_of_day
  rescue ArgumentError, TypeError
    nil
  end

  def metadata_value(key)
    (metadata || {}).with_indifferent_access[key]
  end

  def write_metadata_value(key, value)
    merged = (metadata || {}).with_indifferent_access.merge(key => value)
    self.metadata = merged
  end
end
