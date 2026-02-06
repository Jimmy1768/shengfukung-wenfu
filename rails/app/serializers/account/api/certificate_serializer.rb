# frozen_string_literal: true

module Account
  module Api
    class CertificateSerializer
      def initialize(registration)
        @registration = registration
      end

      def as_json(*)
        {
          certificate_number: registration.certificate_number,
          reference_code: registration.reference_code,
          issued_on: registration.updated_at.iso8601,
          offering: offering_payload,
          registrant: registrant_payload
        }
      end

      private

      attr_reader :registration

      def offering_payload
        return {} unless registration.offering

        {
          id: registration.offering.id,
          title: registration.offering.title,
          period: registration.offering.try(:period) || registration.offering.try(:period_label),
          slug: registration.offering.slug
        }
      end

      def registrant_payload
        user = registration.user
        {
          id: user&.id,
          name: user&.english_name || registration.contact_payload["name"],
          email: user&.email || registration.contact_payload["email"]
        }
      end
    end
  end
end
