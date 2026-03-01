# frozen_string_literal: true

module PaymentGateway
  class StripeAdapter < Adapter
    ConfigurationError = Class.new(StandardError)

    def verify_webhook_signature(payload:, headers:)
      signature = headers["Stripe-Signature"].to_s
      secret = ENV["STRIPE_WEBHOOK_SECRET"].to_s

      return { valid: false, reason: "missing_signature_header" } if signature.blank?
      return { valid: false, reason: "missing_webhook_secret" } if secret.blank?
      return { valid: false, reason: "missing_raw_body" } if payload[:_raw_body].blank? && payload["_raw_body"].blank?
      return { valid: false, reason: "stripe_sdk_missing" } unless stripe_sdk_available?

      Stripe::Webhook.construct_event(raw_body(payload), signature, secret)
      { valid: true, reason: "verified" }
    rescue Stripe::SignatureVerificationError => e
      { valid: false, reason: "invalid_signature:#{e.message}" }
    rescue JSON::ParserError => e
      { valid: false, reason: "invalid_json:#{e.message}" }
    end

    def checkout(intent:, amount_cents:, currency:, metadata:, idempotency_key:)
      ensure_checkout_dependencies!
      configure_stripe!

      mode = checkout_mode(metadata)
      case mode
      when "payment_intent"
        checkout_payment_intent(
          intent: intent,
          amount_cents: amount_cents,
          currency: currency,
          metadata: metadata,
          idempotency_key: idempotency_key
        )
      when "checkout_session"
        checkout_session(
          intent: intent,
          amount_cents: amount_cents,
          currency: currency,
          metadata: metadata,
          idempotency_key: idempotency_key
        )
      else
        raise ArgumentError, "Unsupported stripe checkout mode: #{mode}"
      end
    end

    def ingest_webhook(payload:, headers:)
      signature = verify_webhook_signature(payload: payload, headers: headers)
      event = payload
      if signature[:valid]
        configure_stripe!
        event = Stripe::Webhook.construct_event(raw_body(payload), headers["Stripe-Signature"], ENV["STRIPE_WEBHOOK_SECRET"])
      end

      normalized_event = normalize_event(event)
      {
        event_type: normalized_event[:event_type],
        provider_event_id: normalized_event[:provider_event_id],
        provider_reference: normalized_event[:provider_reference],
        status: normalized_event[:status],
        signature_valid: signature[:valid],
        signature_reason: signature[:reason],
        raw: {
          payload: normalize_hash(event),
          headers: headers.slice("Stripe-Signature")
        }
      }
    end

    def confirm(provider_payment_ref:, amount_cents: nil, currency: nil, metadata: {}, idempotency_key:)
      query_status(provider_payment_ref: provider_payment_ref, metadata: metadata)
    end

    def query_status(provider_payment_ref:, metadata: {})
      ensure_stripe_api_key!
      configure_stripe!

      intent = Stripe::PaymentIntent.retrieve(provider_payment_ref)
      {
        status: map_payment_intent_status(intent.status),
        provider_reference: intent.id,
        raw: {
          payment_intent: normalize_hash(intent),
          metadata: metadata
        }
      }
    end

    def refund(payment_reference:, amount_cents: nil, reason: nil, idempotency_key:)
      ensure_stripe_api_key!
      configure_stripe!

      params = {
        payment_intent: payment_reference
      }
      params[:amount] = amount_cents if amount_cents.present?
      params[:reason] = reason if reason.present?

      refund = Stripe::Refund.create(params, { idempotency_key: idempotency_key })
      {
        status: refund.status == "succeeded" ? "refunded" : "failed",
        provider_reference: payment_reference,
        raw: {
          refund: normalize_hash(refund)
        }
      }
    end

    def cancel(payment_reference:, reason: nil, idempotency_key:)
      ensure_stripe_api_key!
      configure_stripe!

      intent = Stripe::PaymentIntent.cancel(payment_reference, {}, { idempotency_key: idempotency_key })
      {
        status: intent.status == "canceled" ? "canceled" : "failed",
        provider_reference: intent.id,
        raw: {
          payment_intent: normalize_hash(intent),
          reason: reason
        }
      }
    end

    private

    def checkout_payment_intent(intent:, amount_cents:, currency:, metadata:, idempotency_key:)
      params = {
        amount: amount_cents,
        currency: normalized_currency(currency),
        automatic_payment_methods: { enabled: true },
        metadata: normalized_metadata(metadata).merge("intent_key" => intent)
      }
      receipt_email = metadata_value(metadata, "customer_email")
      params[:receipt_email] = receipt_email if receipt_email.present?

      payment_intent = Stripe::PaymentIntent.create(params, { idempotency_key: idempotency_key })
      {
        status: map_payment_intent_status(payment_intent.status),
        provider_payment_id: payment_intent.id,
        provider_reference: payment_intent.id,
        client_secret: payment_intent.client_secret,
        checkout_mode: "payment_intent",
        raw: {
          payment_intent: normalize_hash(payment_intent)
        }
      }
    end

    def checkout_session(intent:, amount_cents:, currency:, metadata:, idempotency_key:)
      success_url = metadata_value(metadata, "success_url")
      cancel_url = metadata_value(metadata, "cancel_url")
      raise ConfigurationError, "stripe checkout_session requires success_url" if success_url.blank?
      raise ConfigurationError, "stripe checkout_session requires cancel_url" if cancel_url.blank?

      session = Stripe::Checkout::Session.create(
        {
          mode: "payment",
          success_url: success_url,
          cancel_url: cancel_url,
          line_items: [
            {
              quantity: 1,
              price_data: {
                currency: normalized_currency(currency),
                product_data: { name: metadata_value(metadata, "item_name").presence || "Registration" },
                unit_amount: amount_cents
              }
            }
          ],
          metadata: normalized_metadata(metadata).merge("intent_key" => intent)
        },
        { idempotency_key: idempotency_key }
      )

      {
        status: "pending",
        provider_checkout_id: session.id,
        provider_payment_id: session.payment_intent,
        provider_reference: session.payment_intent.presence || session.id,
        redirect_url: session.url,
        checkout_mode: "checkout_session",
        raw: {
          checkout_session: normalize_hash(session)
        }
      }
    end

    def normalize_event(event)
      hash = normalize_hash(event)
      event_type = hash["type"].to_s.presence || "stripe.unknown"
      object = hash.dig("data", "object") || {}

      status =
        case event_type
        when "payment_intent.succeeded", "checkout.session.completed"
          "completed"
        when "charge.refunded"
          "refunded"
        when "payment_intent.payment_failed", "payment_intent.canceled"
          "failed"
        else
          object["status"] || "pending"
        end

      provider_reference = object["payment_intent"].presence || object["id"]

      {
        event_type: event_type,
        provider_event_id: hash["id"],
        provider_reference: provider_reference,
        status: status
      }
    end

    def map_payment_intent_status(status)
      case status.to_s
      when "succeeded"
        "completed"
      when "canceled"
        "failed"
      when "processing", "requires_confirmation", "requires_capture", "requires_payment_method", "requires_action"
        "pending"
      else
        "pending"
      end
    end

    def checkout_mode(metadata)
      mode = metadata_value(metadata, "checkout_mode").to_s
      return "payment_intent" if mode.blank?

      mode
    end

    def normalized_currency(currency)
      currency.to_s.downcase
    end

    def normalized_metadata(metadata)
      (metadata || {}).to_h.deep_stringify_keys
    end

    def metadata_value(metadata, key)
      normalized_metadata(metadata)[key]
    end

    def raw_body(payload)
      payload[:_raw_body].presence || payload["_raw_body"].presence
    end

    def normalize_hash(value)
      raw =
        if value.respond_to?(:to_hash)
          value.to_hash
        elsif value.respond_to?(:to_h)
          value.to_h
        else
          value
        end

      raw.is_a?(Hash) ? raw.deep_stringify_keys : raw
    end

    def ensure_checkout_dependencies!
      ensure_stripe_api_key!
      raise ConfigurationError, "Stripe SDK is required for checkout" unless stripe_sdk_available?
    end

    def ensure_stripe_api_key!
      raise ConfigurationError, "STRIPE_SECRET_KEY is missing" if ENV["STRIPE_SECRET_KEY"].to_s.blank?
    end

    def configure_stripe!
      Stripe.api_key = ENV.fetch("STRIPE_SECRET_KEY")
    end

    def stripe_sdk_available?
      defined?(Stripe::PaymentIntent) && defined?(Stripe::Webhook)
    end
  end
end
