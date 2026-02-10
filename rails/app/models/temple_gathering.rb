# frozen_string_literal: true

class TempleGathering < ApplicationRecord
  include TempleScopedSlug
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

  after_destroy :purge_hero_asset

  def location_label
    location_name.presence || location_address.presence
  end

  def free_gathering_enabled?
    meta = (metadata || {})
    return ActiveModel::Type::Boolean.new.cast(meta["free_gathering"]) if meta.key?("free_gathering")
    return false if new_record?

    price_cents.to_i.zero?
  end

  def hero_asset_id
    metadata_value("hero_asset_id")
  end

  def hero_asset_id=(value)
    write_metadata_value("hero_asset_id", value.presence)
  end

  def timeline_status
    today = Date.current
    return :past if ends_on.present? && ends_on < today
    return :upcoming if starts_on.present? && starts_on > today

    :ongoing
  end

  private

  def metadata_value(key)
    (metadata || {}).with_indifferent_access[key]
  end

  def write_metadata_value(key, value)
    data = (metadata || {}).with_indifferent_access
    if value.present?
      data[key] = value
    else
      data.delete(key)
    end
    self.metadata = data
  end

  def purge_hero_asset
    return unless hero_asset_id.present?

    MediaAsset.where(id: hero_asset_id, temple_id: temple_id).destroy_all
  end
end
