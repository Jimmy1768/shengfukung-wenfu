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

  def self.admin_filtered(filters)
    filters ||= {}
    scope = includes(:user, admin_account: :user, temple_event_registration: %i[user temple_offering])
    scope = scope.where(payment_method: filters[:payment_method]) if filters[:payment_method].present?
    if filters[:offering_id].present?
      scope = scope.joins(:temple_event_registration)
        .where(temple_event_registrations: { temple_offering_id: filters[:offering_id] })
    end
    if filters[:query].present?
      sanitized = ActiveRecord::Base.sanitize_sql_like(filters[:query])
      scope = scope.left_outer_joins(temple_event_registration: :user).where(
        "temple_event_registrations.reference_code ILIKE :query OR temple_payments.external_reference ILIKE :query OR users.english_name ILIKE :query OR users.email ILIKE :query OR (temple_event_registrations.contact_payload ->> 'name') ILIKE :query",
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
