# frozen_string_literal: true

class TempleOfferingSerializer
  def initialize(offering)
    @offering = offering
  end

  def as_json(*) # rubocop:disable Metrics/MethodLength
    {
      id: offering.id,
      slug: offering.slug,
      title: offering.title,
      description: offering.description,
      offering_type: offering.offering_type,
      price_cents: offering.price_cents,
      currency: offering.currency,
      period: offering.period,
      starts_on: offering.starts_on&.iso8601,
      ends_on: offering.ends_on&.iso8601,
      available_slots: offering.available_slots,
      capacity_remaining: offering.capacity_remaining,
      active: offering.active?,
      timeline_status: offering.timeline_status.to_s,
      metadata: offering.metadata
    }
  end

  private

  attr_reader :offering
end
