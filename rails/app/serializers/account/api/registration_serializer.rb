# frozen_string_literal: true

module Account
  module Api
    class RegistrationSerializer
      def initialize(registration)
        @registration = registration
      end

      def as_json(*)
        {
          reference_code: registration.reference_code,
          offering: offering_payload,
          quantity: registration.quantity,
          total_amount_cents: registration.total_price_cents,
          currency: registration.currency,
          payment_status: registration.payment_status,
          fulfillment_status: registration.fulfillment_status,
          certificate_number: registration.certificate_number,
          created_at: registration.created_at.iso8601
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
    end
  end
end
