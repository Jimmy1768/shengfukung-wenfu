# frozen_string_literal: true

class TemplePage < ApplicationRecord
  belongs_to :temple
  has_many :temple_sections,
    dependent: :destroy

  enum :kind, {
    home: "home",
    about: "about",
    events: "events",
    services: "services",
    contact: "contact",
    visit: "visit",
    custom: "custom"
  }

  validates :kind, presence: true

  def ordered_sections
    temple_sections.order(:position, :id)
  end
end
