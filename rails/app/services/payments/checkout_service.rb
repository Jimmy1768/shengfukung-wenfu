# frozen_string_literal: true

module Payments
  class CheckoutService
    Result = Struct.new(:payment, :adapter_payload, :reused, keyword_init: true)

    def initialize(provider_resolver: ProviderResolver, payment_repository: Repositories::PaymentRepository.new)
      @provider_resolver = provider_resolver
      @payment_repository = payment_repository
    end

    def call(registration:, amount_cents:, currency:, provider:, idempotency_key:, intent_key:, provider_account: "temple", metadata: {})
      raise ArgumentError, "idempotency_key is required" if idempotency_key.blank?
      raise ArgumentError, "intent_key is required" if intent_key.blank?

      existing = payment_repository.find_by_idempotency(
        temple: registration.temple,
        provider: provider,
        idempotency_key: idempotency_key
      )
      return Result.new(payment: existing, adapter_payload: {}, reused: true) if existing

      completed_for_intent = payment_repository.find_completed_by_intent(
        temple: registration.temple,
        intent_key: intent_key
      )
      if completed_for_intent
        return Result.new(
          payment: completed_for_intent,
          adapter_payload: { reason: "duplicate_intent", intent_key: intent_key },
          reused: true
        )
      end

      payment = payment_repository.create_pending!(
        registration: registration,
        provider: provider,
        provider_account: provider_account,
        payment_method: resolve_payment_method(provider),
        amount_cents: amount_cents,
        currency: currency,
        idempotency_key: idempotency_key,
        intent_key: intent_key,
        metadata: metadata
      )

      adapter_payload = adapter(provider).checkout(
        intent: intent_key,
        amount_cents: amount_cents,
        currency: currency,
        metadata: metadata,
        idempotency_key: idempotency_key
      )

      payment_repository.apply_checkout_result!(
        payment: payment,
        status: map_status(adapter_payload[:status]),
        provider_reference: adapter_payload[:provider_reference] || adapter_payload[:provider_payment_id] || adapter_payload[:provider_checkout_id],
        payload: adapter_payload,
        metadata: metadata
      )

      Result.new(payment: payment, adapter_payload: adapter_payload, reused: false)
    end

    private

    attr_reader :provider_resolver, :payment_repository

    def adapter(provider)
      provider_resolver.resolve(provider: provider)
    end

    def resolve_payment_method(provider)
      if TemplePayment::PAYMENT_METHODS.value?(provider.to_s)
        provider.to_s
      else
        TemplePayment::PAYMENT_METHODS[:cash]
      end
    end

    def map_status(value)
      status = value.to_s
      case status
      when "succeeded", "success", "completed", "paid", TemplePayment::STATUSES[:completed]
        TemplePayment::STATUSES[:completed]
      when "failed", "error", "declined", "canceled", "cancelled", TemplePayment::STATUSES[:failed]
        TemplePayment::STATUSES[:failed]
      when "refunded", "partial_refunded", TemplePayment::STATUSES[:refunded]
        TemplePayment::STATUSES[:refunded]
      else
        TemplePayment::STATUSES[:pending]
      end
    end
  end
end
