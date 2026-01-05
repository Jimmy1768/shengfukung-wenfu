# frozen_string_literal: true

class MediaAsset < ApplicationRecord
  belongs_to :temple

  enum :role, {
    hero_image: "hero_image",
    gallery_image: "gallery_image",
    gallery_video: "gallery_video",
    attachment: "attachment",
    line_pay_qr: "line_pay_qr"
  }

  scope :hero, -> { where(role: :hero_image) }

  validates :file_uid, presence: true

  def url
    metadata.fetch("url", nil)
  end
end
