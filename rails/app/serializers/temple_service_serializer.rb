# frozen_string_literal: true

class TempleServiceSerializer
  def initialize(service)
    @service = service
  end

  def as_json(*)
    {
      id: service.id,
      slug: service.slug,
      title: service.title,
      subtitle: service.subtitle,
      description: service.description,
      offering_type: service.offering_type,
      price_cents: service.price_cents,
      currency: service.currency,
      period_label: service.period_label,
      available_from: service.available_from&.iso8601,
      available_until: service.available_until&.iso8601,
      quantity_limit: service.quantity_limit,
      default_location: service.default_location,
      fulfillment_notes: service.fulfillment_notes,
      hero_image_url: service.hero_image_url,
      metadata: service.metadata
    }
  end

  private

  attr_reader :service
end
