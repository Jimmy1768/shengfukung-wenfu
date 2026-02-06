# frozen_string_literal: true

class TempleGalleryEntry < ApplicationRecord
  belongs_to :temple

  scope :recent_first, -> { order(event_date: :desc, created_at: :desc) }

  validates :title, presence: true

  after_destroy :purge_media_assets

  def event_date
    super || created_at
  end

  def media_asset_ids
    metadata_value("media_asset_ids") || []
  end

  def media_asset_ids=(ids)
    write_metadata_value("media_asset_ids", Array(ids).map(&:to_s))
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

  def purge_media_assets
    ids = media_asset_ids
    return if ids.empty?

    MediaAsset.where(id: ids, temple_id: temple_id).destroy_all
  end
end
