# frozen_string_literal: true

module Account
  module Api
    class GuestListSerializer
      def initialize(offering:, registrations:)
        @offering = offering
        @registrations = registrations
      end

      def as_json(*)
        {
          offering: {
            id: offering.id,
            title: offering.title,
            period: offering.period,
            slug: offering.slug
          },
          guest_count: registrations.count,
          total_quantity: registrations.sum(&:quantity),
          registrations: registrations.map { |registration| guest_entry(registration) }
        }
      end

      private

      attr_reader :offering, :registrations

      def guest_entry(registration)
        {
          reference_code: registration.reference_code,
          quantity: registration.quantity,
          payment_status: registration.payment_status,
          certificate_number: registration.certificate_number,
          registrant: {
            id: registration.user&.id,
            name: registration.user&.english_name || registration.contact_payload["name"],
            email: registration.user&.email || registration.contact_payload["email"]
          }
        }
      end
    end
  end
end
