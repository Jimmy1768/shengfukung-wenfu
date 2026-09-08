# frozen_string_literal: true

# One photo in one album, at one position, in one state.
#
# This exists so that "remove this photo" and "reorder these photos" are
# operations on a record rather than edits to two parallel jsonb arrays that
# nothing kept aligned. It also gives an uploaded photo a durable link to its
# MediaAsset, which is what makes reclaiming the S3 object possible at all --
# previously destroying an album destroyed the asset row and left the object
# behind with nothing pointing at it.
class TempleGalleryPhoto < ApplicationRecord
  STATUSES = %w[active archived].freeze

  belongs_to :temple_gallery_entry
  # Null for a pasted URL; set when the photo came from an upload.
  belongs_to :media_asset, optional: true

  validates :url, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
  scope :archived, -> { where(status: "archived") }
  scope :ordered, -> { order(:position, :id) }

  def archived?
    status == "archived"
  end

  # Reversible, and the gate that makes deletion safe: a photo has to be
  # archived before it can be destroyed, so an operator always passes through a
  # step they can undo. See the archive-gates-delete ruling in
  # ops/docs/plans/GALLERY_AS_MEDIA_ASSETS_PLAN.md.
  def archive!
    update!(status: "archived")
  end

  def restore!
    update!(status: "active")
  end
end
