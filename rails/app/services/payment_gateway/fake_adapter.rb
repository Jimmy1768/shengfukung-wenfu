# frozen_string_literal: true

module PaymentGateway
  class FakeAdapter < Adapter
    def verify_webhook_signature(payload:, headers:)
      { valid: true, reason: "fake_bypass" }
    end

    def checkout(intent:, amount_cents:, currency:, metadata:, idempotency_key:)
      {
        status: "pending",
        provider_checkout_id: "fake_chk_#{SecureRandom.hex(8)}",
        provider_payment_id: "fake_pay_#{SecureRandom.hex(8)}",
        provider_reference: "fake_ref_#{SecureRandom.hex(8)}",
        redirect_url: metadata[:browser_return_url].presence || metadata["browser_return_url"].presence ||
          metadata[:return_url].presence || metadata["return_url"].presence,
        raw: {
          intent: intent,
          amount_cents: amount_cents,
          currency: currency,
          metadata: metadata,
          idempotency_key: idempotency_key
        }
      }
    end

    def ingest_webhook(payload:, headers:)
      signature = verify_webhook_signature(payload: payload, headers: headers)
      {
        event_type: payload[:event_type].presence || payload["event_type"].presence || "payment.updated",
        provider_event_id: payload[:event_id].presence || payload["event_id"].presence || "fake_evt_#{SecureRandom.hex(8)}",
        provider_reference: payload[:provider_reference].presence || payload["provider_reference"].presence || payload[:payment_reference].presence || payload["payment_reference"].presence,
        status: payload[:status].presence || payload["status"].presence || "pending",
        signature_valid: signature[:valid],
        signature_reason: signature[:reason],
        raw: {
          payload: payload,
          headers: headers
        }
      }
    end

    def confirm(provider_payment_ref:, amount_cents: nil, currency: nil, metadata: {}, idempotency_key:)
      {
        status: "completed",
        provider_reference: provider_payment_ref,
        raw: {
          amount_cents: amount_cents,
          currency: currency,
          metadata: metadata,
          idempotency_key: idempotency_key
        }
      }
    end

    def query_status(provider_payment_ref:, metadata: {})
      {
        status: "completed",
        provider_reference: provider_payment_ref,
        raw: {
          metadata: metadata
        }
      }
    end

    def refund(payment_reference:, amount_cents: nil, reason: nil, idempotency_key:)
      {
        status: "refunded",
        provider_reference: payment_reference,
        raw: {
          amount_cents: amount_cents,
          reason: reason,
          idempotency_key: idempotency_key
        }
      }
    end

    def cancel(payment_reference:, reason: nil, idempotency_key:)
      {
        status: "canceled",
        provider_reference: payment_reference,
        raw: {
          reason: reason,
          idempotency_key: idempotency_key
        }
      }
    end
  end
end
