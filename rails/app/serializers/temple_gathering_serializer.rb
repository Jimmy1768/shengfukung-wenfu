# frozen_string_literal: true

class TempleGatheringSerializer
  def initialize(gathering)
    @gathering = gathering
  end

  def as_json(*)
    {
      id: gathering.id,
      kind: "gathering",
      slug: gathering.slug,
      title: gathering.title,
      subtitle: gathering.subtitle,
      description: gathering.description,
      price_cents: gathering.price_cents,
      currency: gathering.currency,
      status: gathering.status,
      starts_on: gathering.starts_on&.iso8601,
      ends_on: gathering.ends_on&.iso8601,
      start_time: gathering.start_time&.strftime("%H:%M"),
      end_time: gathering.end_time&.strftime("%H:%M"),
      location_name: gathering.location_name,
      location_address: gathering.location_address,
      location_notes: gathering.location_notes,
      timeline_status: gathering.timeline_status.to_s,
      hero_image_url: gathering.hero_image_url,
      metadata: gathering.metadata
    }
  end

  private

  attr_reader :gathering
end
