# frozen_string_literal: true

class TempleGalleryEntry < ApplicationRecord
  belongs_to :temple

  scope :recent_first, -> { order(event_date: :desc, created_at: :desc) }

  validates :title, presence: true

  def event_date
    super || created_at
  end
end
