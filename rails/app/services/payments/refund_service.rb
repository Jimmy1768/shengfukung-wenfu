# frozen_string_literal: true

module Payments
  class RefundService
    Result = Struct.new(:payment, :adapter_payload, keyword_init: true)

    def initialize(provider_resolver: ProviderResolver, payment_repository: Repositories::PaymentRepository.new)
      @provider_resolver = provider_resolver
      @payment_repository = payment_repository
    end

    def call(payment:, amount_cents: nil, reason: nil, idempotency_key:, operation: :refund)
      raise ArgumentError, "idempotency_key is required" if idempotency_key.blank?

      adapter_payload = if operation.to_sym == :cancel
        adapter(payment.provider).cancel(
          payment_reference: payment.provider_reference.presence || payment.external_reference.presence || payment.id.to_s,
          reason: reason,
          idempotency_key: idempotency_key
        )
      else
        adapter(payment.provider).refund(
          payment_reference: payment.provider_reference.presence || payment.external_reference.presence || payment.id.to_s,
          amount_cents: amount_cents,
          reason: reason,
          idempotency_key: idempotency_key
        )
      end

      payment_repository.update_status!(
        payment: payment,
        status: map_status(adapter_payload[:status]),
        payload: adapter_payload,
        metadata: {
          refund_reason: reason,
          operation: operation.to_sym
        }.compact
      )
      sync_registration_status!(payment)

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
      return TemplePayment::STATUSES[:failed] if %w[canceled cancelled].include?(status)

      TemplePayment::STATUSES[:failed]
    end

    def sync_registration_status!(payment)
      registration = payment.temple_registration
      return unless registration

      case payment.status
      when TemplePayment::STATUSES[:refunded]
        registration.update!(payment_status: TempleRegistration::PAYMENT_STATUSES[:refunded])
      when TemplePayment::STATUSES[:failed]
        registration.update!(payment_status: TempleRegistration::PAYMENT_STATUSES[:failed])
      when TemplePayment::STATUSES[:completed]
        registration.mark_paid! unless registration.paid?
      end
    end
  end
end
