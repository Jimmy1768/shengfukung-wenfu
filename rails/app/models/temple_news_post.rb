# frozen_string_literal: true

class TempleNewsPost < ApplicationRecord
  belongs_to :temple

  scope :published, -> { where(published: true) }
  scope :recent_first, -> { order(published_at: :desc, created_at: :desc) }

  validates :title, presence: true

  def published_at
    super || created_at
  end
end
