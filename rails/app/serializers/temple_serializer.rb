# frozen_string_literal: true

class TempleSerializer
  def initialize(temple)
    @temple = temple
  end

  def as_json(*)
    {
      slug: temple.slug,
      name: temple.name,
      tagline: temple.tagline,
      hero_copy: temple.hero_copy,
      about_html: temple.about_html,
      contact: contact_payload,
      service_times: service_times_payload,
      visit_info: visit_info_payload,
      about: about_payload,
      metadata: temple.metadata,
      hero_images: hero_images_payload,
      pages: pages_json,
      media_assets: media_json
    }
  end

  private

  attr_reader :temple

  def pages_json
    temple.temple_pages.order(:position, :id).map do |page|
      {
        id: page.id,
        kind: page.kind,
        slug: page.slug,
        title: page.title,
        meta: page.meta,
        sections: page.ordered_sections.map { |section| section_json(section) }
      }
    end
  end

  def section_json(section)
    {
      id: section.id,
      section_type: section.section_type,
      title: section.title,
      body: section.body,
      payload: section.payload_data,
      position: section.position
    }
  end

  def media_json
    temple.media_assets.map do |asset|
      {
        id: asset.id,
        role: asset.role,
        alt_text: asset.alt_text,
        credit: asset.credit,
        url: asset.url || asset.file_uid,
        metadata: asset.metadata
      }
    end
  end

  # These four returned AppConstants::TempleProfilePlaceholders when a temple had
  # written nothing, which meant the public API served admin instructions --
  # "尚未設定地址（請至後台「Temple Profile」更新）" and the rest -- to anyone who
  # asked for a temple that had not filled a section in. Observed 2026-09-25 on
  # the public footer, where those strings reached real visitors.
  #
  # An empty hash rather than nil: a consumer reading `contact.phone` gets
  # nothing instead of raising, which is the same shape it already handled for a
  # field a temple had left blank. The site hides what is empty; the API's job is
  # to say there is nothing, not to invent something to say.
  def contact_payload
    temple.contact_details.presence || {}
  end

  def service_times_payload
    temple.service_schedule.presence || {}
  end

  def visit_info_payload
    temple.visit_info.presence || {}
  end

  def about_payload
    temple.about_content.presence || {}
  end

  def hero_images_payload
    temple.hero_images_with_fallback
  end
end
