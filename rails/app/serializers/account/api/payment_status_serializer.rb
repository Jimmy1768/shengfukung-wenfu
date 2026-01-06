# frozen_string_literal: true

module Account
  module Api
    class PaymentStatusSerializer
      def initialize(registration)
        @registration = registration
      end

      def as_json(*)
        {
          reference_code: registration.reference_code,
          payment_status: registration.payment_status,
          fulfillment_status: registration.fulfillment_status,
          total_amount_cents: registration.total_price_cents,
          currency: registration.currency,
          certificate_number: registration.certificate_number,
          payments: payments_payload,
          last_payment_at: last_payment_at&.iso8601
        }
      end

      private

      attr_reader :registration

      def payments_payload
        registration.temple_payments.order(Arel.sql("COALESCE(temple_payments.processed_at, temple_payments.created_at) DESC")).map do |payment|
          {
            id: payment.id,
            method: payment.payment_method,
            status: payment.status,
            amount_cents: payment.amount_cents,
            currency: payment.currency,
            processed_at: (payment.processed_at || payment.created_at)&.iso8601,
            external_reference: payment.external_reference
          }
        end
      end

      def last_payment_at
        registration.temple_payments
          .order(Arel.sql("COALESCE(temple_payments.processed_at, temple_payments.created_at) DESC"))
          .limit(1)
          .pick(Arel.sql("COALESCE(temple_payments.processed_at, temple_payments.created_at)"))
      end
    end
  end
end
