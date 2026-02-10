# frozen_string_literal: true

class TempleEventSerializer
  def initialize(event)
    @event = event
  end

  def as_json(*)
    {
      id: event.id,
      kind: "event",
      slug: event.slug,
      title: event.title,
      subtitle: event.subtitle,
      description: event.description,
      offering_type: event.offering_type,
      price_cents: event.price_cents,
      currency: event.currency,
      period: event.period,
      starts_on: event.starts_on&.iso8601,
      ends_on: event.ends_on&.iso8601,
      start_time: event.start_time&.strftime("%H:%M"),
      end_time: event.end_time&.strftime("%H:%M"),
      location_name: event.location_label,
      location_address: event.location_address,
      location_notes: event.location_notes,
      available_slots: event.available_slots,
      capacity_remaining: event.capacity_remaining,
      timeline_status: event.timeline_status.to_s,
      hero_image_url: event.hero_image_url,
      poster_image_url: event.poster_image_url,
      metadata: event.metadata
    }
  end

  private

  attr_reader :event
end
