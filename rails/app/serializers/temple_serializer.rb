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
      metadata: temple.metadata,
      primary_image_url: temple.primary_image_url,
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

  def contact_payload
    data = temple.contact_details
    return data if data.present?

    AppConstants::TempleProfilePlaceholders.contact
  end

  def service_times_payload
    data = temple.service_schedule
    return data if data.present?

    AppConstants::TempleProfilePlaceholders.service_times
  end

  def visit_info_payload
    data = temple.visit_info
    return data if data.present?

    AppConstants::TempleProfilePlaceholders.visit_info
  end

  def hero_images_payload
    temple.hero_images_with_fallback
  end
end
