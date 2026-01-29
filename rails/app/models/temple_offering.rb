# frozen_string_literal: true

class TempleOffering < ApplicationRecord
  # Pretend to be an `Offering` so polymorphic route helpers pick the existing
  # `admin_offering*` paths even though the database model is TempleOffering.
  def self.model_name
    ActiveModel::Name.new(self, nil, "Offering")
  end
  self.table_name = "temple_offerings"

  OFFERING_TYPES = {
    general: "general",
    lamp: "lamp",
    ritual: "ritual",
    donation: "donation",
    table: "table"
  }.freeze

  belongs_to :temple
  has_many :temple_event_registrations,
    foreign_key: :temple_offering_id,
    dependent: :restrict_with_error
  has_many :temple_payments, through: :temple_event_registrations

  validates :slug, :title, :offering_type, :currency, presence: true
  validates :slug, uniqueness: { scope: :temple_id }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :available_slots, numericality: { allow_nil: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :for_type, ->(type) { where(offering_type: type) }
  scope :order_for_marketing, lambda {
    order(Arel.sql("COALESCE(starts_on, CURRENT_DATE) ASC, title ASC"))
  }
  scope :upcoming_or_active, lambda {
    today = Date.current
    where(active: true)
      .where(
        arel_table[:ends_on].eq(nil).or(arel_table[:ends_on].gteq(today))
      )
  }
  scope :past_events, lambda {
    today = Date.current
    where.not(ends_on: nil).where(arel_table[:ends_on].lt(today))
  }

  before_validation :assign_slug

  def capacity_remaining
    return nil if available_slots.blank?

    available_slots - temple_event_registrations.count
  end

  def timeline_status
    today = Date.current
    return :past if ended_before?(today)
    return :upcoming if starts_on.present? && starts_on > today

    :ongoing
  end

  private

  def ended_before?(date)
    ends_on.present? && ends_on < date
  end

  def assign_slug
    return if slug.present?

    base = title.to_s.parameterize
    self.slug = base.presence || SecureRandom.hex(4)
  end
end
