# frozen_string_literal: true

module PaymentGateway
  class StripeAdapter < Adapter
    def checkout(**)
      raise NotImplementedError, "Stripe adapter checkout is scaffolded but not implemented yet."
    end

    def ingest_webhook(payload:, headers:)
      {
        event_type: payload[:type].presence || payload["type"].presence || "stripe.unknown",
        provider_event_id: payload[:id].presence || payload["id"],
        provider_reference: payload.dig(:data, :object, :id) || payload.dig("data", "object", "id"),
        status: payload.dig(:data, :object, :status) || payload.dig("data", "object", "status"),
        signature_valid: headers["Stripe-Signature"].present?,
        raw: {
          payload: payload,
          headers: headers
        }
      }
    end

    def confirm(**)
      raise NotImplementedError, "Stripe adapter confirm is scaffolded but not implemented yet."
    end

    def query_status(**)
      raise NotImplementedError, "Stripe adapter query_status is scaffolded but not implemented yet."
    end

    def refund(**)
      raise NotImplementedError, "Stripe adapter refund is scaffolded but not implemented yet."
    end

    def cancel(**)
      raise NotImplementedError, "Stripe adapter cancel is scaffolded but not implemented yet."
    end
  end
end
