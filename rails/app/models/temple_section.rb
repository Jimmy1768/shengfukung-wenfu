# frozen_string_literal: true

class TempleSection < ApplicationRecord
  belongs_to :temple_page

  enum :section_type, {
    hero: "hero",
    story: "story",
    event_list: "event_list",
    news_list: "news_list",
    services_list: "services_list",
    contact_info: "contact_info",
    gallery: "gallery",
    faq: "faq",
    custom: "custom"
  }

  validates :section_type, presence: true

  def payload_data
    payload.presence || {}
  end
end
