# frozen_string_literal: true

module Payments
  class OfferingRegistrationBuilder
    def initialize(temple:, offering:, admin_user:, attributes:)
      @temple = temple
      @offering = offering
      @admin_user = admin_user
      @attributes = attributes.to_h.deep_symbolize_keys
    end

    def create
      TempleEventRegistration.transaction do
        registration = temple.temple_event_registrations.new(registration_attributes)
        registration.temple_offering ||= offering
        registration.event_slug ||= offering.slug
        registration.save!

        persist_user_defaults(registration)

        SystemAuditLogger.log!(
          action: "temple.registration.create",
          admin: admin_user,
          target: registration,
          metadata: {
            offering_id: offering.id,
            reference_code: registration.reference_code
          },
          temple:
        )

        registration
      end
    end

    private

    attr_reader :temple, :offering, :admin_user, :attributes

    def multi_value_fields
      @multi_value_fields ||= Array(@attributes.delete(:multi_value_fields)).map(&:to_s)
    end

    def registration_attributes
      {
        temple_offering: offering,
        user_id: attributes[:user_id],
        quantity: attributes[:quantity].presence || 1,
        unit_price_cents: unit_price_cents,
        currency: attributes[:currency].presence || offering.currency,
        certificate_number: attributes[:certificate_number],
        event_slug: attributes[:event_slug].presence || offering.slug,
        contact_payload: attributes[:contact_payload].presence || {},
        logistics_payload: attributes[:logistics_payload].presence || {},
        metadata: attributes[:metadata].presence || {}
      }
    end

    def unit_price_cents
      value = attributes[:unit_price_cents]
      return offering.price_cents if value.blank? || value.to_i.zero?

      value.to_i
    end

    def persist_user_defaults(registration)
      user = registration.user
      return unless user

      Registrations::UserMetadataUpdater.new(
        user:,
        offering_slug: registration.event_slug || offering.slug,
        contact_payload: attributes[:contact_payload],
        logistics_payload: attributes[:logistics_payload],
        ritual_metadata: attributes[:metadata],
        order_details: {
          quantity: registration.quantity,
          certificate_number: registration.certificate_number
        },
        multi_value_fields: multi_value_fields
      ).update!
    end
  end
end
