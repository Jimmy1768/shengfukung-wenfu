# frozen_string_literal: true

class TempleGalleryEntry < ApplicationRecord
  belongs_to :temple
  has_many :photos,
    -> { ordered },
    class_name: "TempleGalleryPhoto",
    inverse_of: :temple_gallery_entry,
    dependent: :destroy,
    # Required for photo_urls= -- mark_for_destruction is a no-op without it.
    autosave: true

  scope :recent_first, -> { order(event_date: :desc, created_at: :desc) }

  validates :title, presence: true

  after_destroy :purge_media_assets

  # Kept as a method so the nine existing read sites -- admin views, the account
  # portal, two APIs and Archive.vue -- carry on unchanged while the photos
  # themselves live in rows. It reads from the association rather than a stored
  # copy, so there is one writer for one fact.
  def photo_urls
    photos.select { |photo| !photo.archived? }.map(&:url)
  end

  # Replaces the whole set from a list of URLs, preserving each photo's
  # media_asset link where the URL is unchanged. Order is the order given.
  def photo_urls=(urls)
    wanted = Array(urls).map { |u| u.to_s.strip }.reject(&:empty?)
    existing = photos.index_by(&:url)

    photos.each { |photo| photo.mark_for_destruction unless wanted.include?(photo.url) }

    wanted.each_with_index do |url, index|
      if (photo = existing[url])
        photo.position = index
        photo.status = "active"
      else
        photos.build(url:, position: index)
      end
    end
  end

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

  # Destroys the MediaAsset rows an album owned. Note this still does not remove
  # the S3 objects -- MediaAsset has no such hook yet. What changed is that each
  # photo now records its own media_asset_id, so the objects are identifiable
  # rather than orphaned beyond recovery, which is the precondition for
  # reclaiming them once archive/delete exists.
  def purge_media_assets
    ids = (photos.filter_map(&:media_asset_id) + media_asset_ids).uniq
    return if ids.empty?

    MediaAsset.where(id: ids, temple_id: temple_id).destroy_all
  end
end
