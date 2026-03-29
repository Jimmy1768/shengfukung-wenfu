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
  belongs_to :temple_registration
  belongs_to :temple_event_registration,
    class_name: "TempleRegistration",
    foreign_key: :temple_registration_id
  belongs_to :user, optional: true
  belongs_to :financial_ledger_entry, optional: true
  belongs_to :admin_account, optional: true

  delegate :registrable, to: :temple_registration, allow_nil: true

  validates :payment_method, inclusion: { in: PAYMENT_METHODS.values }
  validates :status, inclusion: { in: STATUSES.values }
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true

  scope :completed, -> { where(status: STATUSES[:completed]) }

  def cash?
    payment_method == PAYMENT_METHODS[:cash]
  end

  def pending?
    status == STATUSES[:pending]
  end

  def completed?
    status == STATUSES[:completed]
  end

  def failed?
    status == STATUSES[:failed]
  end

  def refunded?
    status == STATUSES[:refunded]
  end

  def offering_registration
    temple_registration
  end

  def offering
    registrable
  end

  def self.admin_filtered(filters)
    filters ||= {}
    scope = includes(:user, { admin_account: :user }, :temple_registration)
    scope = scope.where(payment_method: filters[:payment_method]) if filters[:payment_method].present?
    scope = scope.where(status: filters[:status]) if filters[:status].present?
    if filters[:offering_type].present?
      table = TempleRegistration.table_name
      type_values = TempleRegistration.offering_type_filter_values(filters[:offering_type])
      scope = scope.joins(:temple_registration)
        .where(
          table => {
            registrable_type: type_values
          }
        )
      scope = scope.where(table => { registrable_id: filters[:offering_id] }) if filters[:offering_id].present?
    end
    if filters[:query].present?
      sanitized = ActiveRecord::Base.sanitize_sql_like(filters[:query])
      table = TempleRegistration.table_name
      scope = scope.left_outer_joins(temple_registration: :user).where(
        "#{table}.reference_code ILIKE :query OR temple_payments.external_reference ILIKE :query OR users.english_name ILIKE :query OR users.email ILIKE :query OR (#{table}.contact_payload ->> 'name') ILIKE :query",
        query: "%#{sanitized}%"
      )
    end
    timestamp_sql = "COALESCE(temple_payments.processed_at, temple_payments.created_at)"
    if (start_at = parse_admin_filter_date(filters[:start_date]))
      scope = scope.where("#{timestamp_sql} >= ?", start_at)
    end
    if (end_at = parse_admin_filter_date(filters[:end_date], end_of_day: true))
      scope = scope.where("#{timestamp_sql} <= ?", end_at)
    end
    scope
  end

  def self.parse_admin_filter_date(value, end_of_day: false)
    return nil if value.blank?

    timestamp = Time.zone.parse(value.to_s)
    return nil unless timestamp

    end_of_day ? timestamp.end_of_day : timestamp.beginning_of_day
  rescue ArgumentError, TypeError
    nil
  end
end
