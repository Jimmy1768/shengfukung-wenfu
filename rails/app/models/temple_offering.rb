# frozen_string_literal: true

class TempleOffering < ApplicationRecord
  OFFERING_TYPES = {
    general: "general",
    lamp: "lamp",
    ritual: "ritual",
    donation: "donation",
    table: "table"
  }.freeze

  belongs_to :temple
  has_many :temple_event_registrations, dependent: :restrict_with_error
  has_many :temple_payments, through: :temple_event_registrations

  validates :slug, :title, :offering_type, :currency, presence: true
  validates :slug, uniqueness: { scope: :temple_id }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :available_slots, numericality: { allow_nil: true, greater_than_or_equal_to: 0 }
  validates :offering_type, inclusion: { in: OFFERING_TYPES.values }

  scope :active, -> { where(active: true) }
  scope :for_type, ->(type) { where(offering_type: type) }

  before_validation :assign_slug

  def capacity_remaining
    return nil if available_slots.blank?

    available_slots - temple_event_registrations.count
  end

  private

  def assign_slug
    return if slug.present?

    base = title.to_s.parameterize
    self.slug = base.presence || SecureRandom.hex(4)
  end
end
