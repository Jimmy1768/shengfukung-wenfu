# frozen_string_literal: true

class TempleService < ApplicationRecord
  include TempleScopedSlug
  self.table_name = "temple_services"

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
  validates :quantity_limit, numericality: { allow_nil: true, greater_than_or_equal_to: 0 }
  validate :registration_period_key_allowed_for_temple

  scope :published_visible, -> { where(status: "published") }

  def available_slots
    quantity_limit
  end

  def offering_type
    metadata_value("offering_type") || "service"
  end

  def offering_type=(value)
    write_metadata_value("offering_type", value.presence)
  end

  def available?
    return true if available_from.blank? && available_until.blank?

    today = Date.current
    after_start = available_from.blank? || available_from <= today
    before_end = available_until.blank? || available_until >= today
    after_start && before_end
  end

  private

  def registration_period_key_allowed_for_temple
    return if registration_period_key.blank?
    return unless temple

    allowed_keys = temple.registration_period_keys
    return if allowed_keys.include?(registration_period_key.to_s)

    errors.add(:registration_period_key, "must match a configured temple registration period key")
  end

  def metadata_value(key)
    (metadata || {}).with_indifferent_access[key]
  end

  def write_metadata_value(key, value)
    merged = (metadata || {}).with_indifferent_access.merge(key => value)
    self.metadata = merged
  end

end
