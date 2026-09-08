# frozen_string_literal: true

class MediaAsset < ApplicationRecord
  belongs_to :temple

  enum :role, {
    hero_image: "hero_image",
    gathering_hero: "gathering_hero",
    gallery_image: "gallery_image",
    gallery_video: "gallery_video",
    attachment: "attachment"
  }

  scope :hero, -> { where(role: :hero_image) }

  validates :file_uid, presence: true
  validate :file_uid_is_a_storage_key

  # Nothing in this application had ever deleted an S3 object. Destroying an
  # asset row removed the only record of where the file lived, leaving it in the
  # bucket with nothing pointing at it -- unfindable and permanent. The row owns
  # the object, so the row is what reclaims it.
  after_destroy_commit :delete_object_from_storage

  def url
    metadata.fetch("url", nil)
  end

  private

  def delete_object_from_storage
    key = file_uid.to_s
    return if key.blank?

    # Legacy rows store a full URL here rather than a key -- seeds created them
    # for images this application never uploaded. There is no object of ours
    # behind those, and namespaced_key would happily build "prod/https://..."
    # and address something that was never mine to remove.
    return if key.start_with?("http://", "https://")

    # Another asset may point at the same object; the last one out reclaims it.
    return if self.class.where.not(id:).exists?(file_uid: key)

    Storage::S3Service.delete(key:)
  rescue StandardError => error
    # The row is already gone and re-raising cannot bring it back. A missed
    # object is a leak, not a corruption, so it is logged rather than fatal.
    Rails.logger.warn("[MediaAsset] could not delete #{key.inspect}: #{error.class}: #{error.message}")
  end

  # file_uid is the S3 key returned by Storage::S3Service.upload, always. Rows
  # that carried a full URL here -- seeds used to create them for images it had
  # never uploaded -- broke the Phase 0 prefix migration, which would have
  # rewritten them to "prod/https://placehold.co/...". Enforced rather than
  # assumed, so that class of bug cannot come back.
  def file_uid_is_a_storage_key
    return if file_uid.blank?
    return unless file_uid.to_s.start_with?("http://", "https://")

    errors.add(:file_uid, "must be a storage key, not a URL")
  end
end
