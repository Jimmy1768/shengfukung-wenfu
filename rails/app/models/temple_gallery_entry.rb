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

  before_destroy :capture_asset_ids_for_purge, prepend: true
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
    # Archived photos are deliberately out of scope. The list this writes from
    # is the admin textarea, which shows only what is live, so treating an
    # archived photo as "absent from the list" destroyed it on the very next
    # save -- which would make Restore useless and archive irreversible.
    live = photos.reject(&:archived?)
    existing = live.index_by(&:url)

    live.each { |photo| photo.mark_for_destruction unless wanted.include?(photo.url) }

    wanted.each_with_index do |url, index|
      if (photo = existing[url])
        photo.position = index
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
    ids = (@asset_ids_before_destroy.to_a + media_asset_ids).uniq
    return if ids.empty?

    MediaAsset.where(id: ids, temple_id: temple_id).destroy_all
  end

  # Captured before dependent: :destroy removes the rows, because after_destroy
  # runs too late to read them. media_asset_ids is still consulted alongside so
  # that albums predating temple_gallery_photos, whose link lives only in that
  # legacy array, still release their files.
  def capture_asset_ids_for_purge
    @asset_ids_before_destroy = photos.filter_map(&:media_asset_id)
  end
end
