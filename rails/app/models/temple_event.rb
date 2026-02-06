# frozen_string_literal: true

class TempleEvent < ApplicationRecord
  include TempleScopedSlug

  self.table_name = "temple_events"

  OFFERING_TYPES = {
    general: "general",
    lamp: "lamp",
    ritual: "ritual",
    donation: "donation",
    table: "table"
  }.freeze

  TIMELINE_STATUSES = %i[upcoming ongoing past].freeze

  belongs_to :temple
  has_many :temple_event_registrations,
    class_name: "TempleRegistration",
    as: :registrable,
    dependent: :restrict_with_error
  has_many :temple_payments,
    through: :temple_event_registrations

  validates :slug, :title, :currency, presence: true
  validates :slug, uniqueness: { scope: :temple_id }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :available_slots, numericality: { allow_nil: true, greater_than_or_equal_to: 0 }

  scope :published_visible, -> { where(status: "published") }
  scope :order_for_marketing, lambda {
    order(
      Arel.sql(
        "COALESCE(temple_events.starts_on, CURRENT_DATE) ASC, temple_events.title ASC"
      )
    )
  }
  scope :upcoming_or_active, lambda {
    today = Date.current
    where(status: "published")
      .where(
        arel_table[:ends_on].eq(nil).or(arel_table[:ends_on].gteq(today))
      )
  }
  scope :past_events, lambda {
    today = Date.current
    where(status: "published").where.not(ends_on: nil).where(arel_table[:ends_on].lt(today))
  }

  def capacity_remaining
    slots = available_slots.presence || capacity_total
    return nil if slots.blank?

    remaining = slots.to_i - temple_event_registrations.count
    [remaining, 0].max
  end

  # --- Legacy offering attributes stored in metadata ------------------------
  def offering_type
    metadata_value("offering_type") || "event"
  end

  def offering_type=(value)
    write_metadata_value("offering_type", value.presence)
  end

  def period
    metadata_value("period")
  end

  def period=(value)
    write_metadata_value("period", value.presence)
  end

  def available_slots
    metadata_value("available_slots")
  end

  def available_slots=(value)
    write_metadata_value("available_slots", value.presence&.to_i)
  end

  def timeline_status
    today = Date.current
    return :past if ended_before?(today)
    return :upcoming if starts_on.present? && starts_on > today

    :ongoing
  end

  def location_label
    location_name.presence || location_address.presence || temple&.contact_details&.dig("addressZh")
  end

  private

  def ended_before?(date)
    ends_on.present? && ends_on < date
  end

  def metadata_value(key)
    (metadata || {}).with_indifferent_access[key]
  end

  def write_metadata_value(key, value)
    merged = (metadata || {}).with_indifferent_access.merge(key => value)
    self.metadata = merged
  end

end
