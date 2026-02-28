# frozen_string_literal: true

module PaymentGateway
  class LinePayAdapter < Adapter
    def checkout(**)
      raise NotImplementedError, "LINE Pay adapter checkout is scaffolded but not implemented yet."
    end

    def ingest_webhook(payload:, headers:)
      {
        event_type: payload[:event_type].presence || payload["event_type"].presence || "line_pay.unknown",
        provider_event_id: payload[:transactionId].presence || payload["transactionId"],
        provider_reference: payload[:orderId].presence || payload["orderId"],
        status: payload[:returnCode].presence || payload["returnCode"],
        signature_valid: headers["x-line-signature"].present?,
        raw: {
          payload: payload,
          headers: headers
        }
      }
    end

    def confirm(**)
      raise NotImplementedError, "LINE Pay adapter confirm is scaffolded but not implemented yet."
    end

    def query_status(**)
      raise NotImplementedError, "LINE Pay adapter query_status is scaffolded but not implemented yet."
    end

    def refund(**)
      raise NotImplementedError, "LINE Pay adapter refund is scaffolded but not implemented yet."
    end

    def cancel(**)
      raise NotImplementedError, "LINE Pay adapter cancel is scaffolded but not implemented yet."
    end
  end
end
