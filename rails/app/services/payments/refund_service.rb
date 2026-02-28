# frozen_string_literal: true

module Payments
  class RefundService
    Result = Struct.new(:payment, :adapter_payload, keyword_init: true)

    def initialize(provider_resolver: ProviderResolver, payment_repository: Repositories::PaymentRepository.new)
      @provider_resolver = provider_resolver
      @payment_repository = payment_repository
    end

    def call(payment:, amount_cents: nil, reason: nil, idempotency_key:)
      adapter_payload = adapter(payment.provider).refund(
        payment_reference: payment.provider_reference.presence || payment.external_reference.presence || payment.id.to_s,
        amount_cents: amount_cents,
        reason: reason,
        idempotency_key: idempotency_key
      )

      payment_repository.update_status!(
        payment: payment,
        status: map_status(adapter_payload[:status]),
        payload: adapter_payload,
        metadata: { refund_reason: reason }.compact
      )

      Result.new(payment: payment, adapter_payload: adapter_payload)
    end

    private

    attr_reader :provider_resolver, :payment_repository

    def adapter(provider)
      provider_resolver.resolve(provider: provider)
    end

    def map_status(value)
      status = value.to_s
      return TemplePayment::STATUSES[:refunded] if %w[refunded partial_refunded].include?(status)

      TemplePayment::STATUSES[:failed]
    end
  end
end
