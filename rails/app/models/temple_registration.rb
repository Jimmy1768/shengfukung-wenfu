# frozen_string_literal: true

class TempleRegistration < ApplicationRecord
  DEFAULT_HOLD_DURATION_HOURS = 24

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
  before_validation :assign_default_expires_at, on: :create
  before_validation :clear_expires_at_when_not_pending

  scope :recent, -> { order(created_at: :desc) }
  scope :with_status, ->(status) { where(payment_status: status) }
  scope :active_for_capacity, -> { where.not(fulfillment_status: FULFILLMENT_STATUSES[:cancelled]) }
  scope :expired_pending_payment_holds, lambda { |now = Time.current|
    where(payment_status: PAYMENT_STATUSES[:pending], fulfillment_status: FULFILLMENT_STATUSES[:open])
      .where("total_price_cents > 0")
      .where("expires_at IS NOT NULL AND expires_at <= ?", now)
  }
  scope :with_certificate_number, lambda {
    where(Arel.sql("#{certificate_number_sql} <> ''"))
  }
  scope :without_certificate_number, lambda {
    where(Arel.sql("#{certificate_number_sql} = ''"))
  }

  def self.admin_filtered(filters)
    filters ||= {}
    scope = includes(:user, :temple_payments).preload(:registrable)
    if filters[:offering_type].present?
      type_values = offering_type_filter_values(filters[:offering_type])
      scope = scope.where(registrable_type: type_values)
      scope = scope.where(registrable_id: filters[:offering_id]) if filters[:offering_id].present?
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

  def no_payment_required?
    total_price_cents.to_i.zero?
  end

  def payment_status_for_display
    return "no_payment_required" if no_payment_required?

    payment_status
  end

  def mark_paid!
    update!(payment_status: PAYMENT_STATUSES[:paid], expires_at: nil)
  end

  def self.hold_duration
    hours = ENV.fetch("REGISTRATION_HOLD_DURATION_HOURS", DEFAULT_HOLD_DURATION_HOURS).to_i
    hours = DEFAULT_HOLD_DURATION_HOURS if hours <= 0
    hours.hours
  end

  def self.cancel_expired_unpaid!(now: Time.current)
    cancelled = 0
    expired_pending_payment_holds(now).find_each do |registration|
      next unless registration.cancel_pending_hold!(now:)

      cancelled += 1
    end
    cancelled
  end

  def cancel_pending_hold!(now: Time.current)
    return false unless payment_status == PAYMENT_STATUSES[:pending]
    return false unless fulfillment_status == FULFILLMENT_STATUSES[:open]
    return false if total_price_cents.to_i <= 0
    return false if expires_at.blank? || expires_at > now
    return false if temple_payments.exists?

    update!(
      fulfillment_status: FULFILLMENT_STATUSES[:cancelled],
      cancelled_at: now,
      expires_at: nil
    )
    true
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

  def registrant_name
    payload = contact_payload || {}
    if dependent_registration?
      metadata_value("registrant_name") ||
        payload["primary_contact"] ||
        payload["contact_name"] ||
        payload["name"] ||
        user&.english_name ||
        user&.email ||
        "訪客"
    else
      user&.english_name ||
        payload["primary_contact"] ||
        payload["contact_name"] ||
        payload["name"] ||
        user&.email ||
        "訪客"
    end
  end

  def registrant_scope
    metadata_value("registrant_scope").presence || (dependent_registration? ? "dependent" : "self")
  end

  def dependent_registration?
    metadata_value("dependent_id").present?
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

  def assign_default_expires_at
    return if expires_at.present?
    return unless hold_required?

    self.expires_at = Time.current + self.class.hold_duration
  end

  def clear_expires_at_when_not_pending
    return if hold_required?

    self.expires_at = nil
  end

  def hold_required?
    payment_status == PAYMENT_STATUSES[:pending] &&
      fulfillment_status == FULFILLMENT_STATUSES[:open] &&
      total_price_cents.to_i.positive?
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

  def self.certificate_number_sql
    "COALESCE((#{table_name}.metadata ->> 'certificate_number'), '')"
  end
end
