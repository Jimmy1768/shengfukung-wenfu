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

  # Read-only, and legacy. temple_gallery_photos.media_asset_id owns the link
  # between a photo and its stored file; nothing has written this array since
  # 572e599. It survives only so that albums predating that migration, whose
  # link exists nowhere else, still release their files when destroyed --
  # purge_media_assets is its one remaining reader. The writer was removed
  # rather than left to tempt a second source of truth back into existence.
  def media_asset_ids
    metadata_value("media_asset_ids") || []
  end

  private

  def metadata_value(key)
    (metadata || {}).with_indifferent_access[key]
  end

  # Destroys the MediaAsset rows an album owned, which since d3f06a6 also deletes
  # their S3 objects through MediaAsset#after_destroy_commit. Deleting an album
  # is therefore genuinely destructive, and is confirmed before it runs.
  #
  # An earlier version of this comment said the objects were left behind because
  # MediaAsset had no such hook. That was true when written and stopped being
  # true one commit later.
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
