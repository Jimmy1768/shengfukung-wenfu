# frozen_string_literal: true

module Payments
  class CheckoutReturnService
    Result = Struct.new(:payment, :adapter_payload, keyword_init: true)

    def initialize(provider_resolver: ProviderResolver, payment_repository: Repositories::PaymentRepository.new, audit_logger: SystemAuditLogger)
      @provider_resolver = provider_resolver
      @payment_repository = payment_repository
      @audit_logger = audit_logger
    end

    def call(registration:, provider:, params: {})
      payment = latest_payment_for!(registration: registration, provider: provider)
      previous_status = payment.status
      payload_params = normalize_params(params)

      adapter_payload = adapter(provider, temple: registration.temple).query_status(
        provider_payment_ref: provider_reference_for_query(payment: payment, params: payload_params),
        metadata: adapter_metadata(registration: registration, payment: payment, params: payload_params)
      )

      payment_repository.update_status!(
        payment: payment,
        status: Payments::StatusMapper.map(adapter_payload[:status]),
        payload: adapter_payload,
        metadata: {
          checkout_return: payload_params.except("canceled")
        },
        provider_reference: adapter_payload[:provider_reference].presence || payload_params["transaction_id"].presence || payload_params["order_id"].presence
      )
      Payments::RegistrationPaymentSync.call(payment, audit_logger: audit_logger)
      log_reconciliation_event!(
        registration: registration,
        payment: payment,
        provider: provider,
        previous_status: previous_status,
        return_params: payload_params
      )

      Result.new(payment: payment, adapter_payload: adapter_payload)
    end

    private

    attr_reader :provider_resolver, :payment_repository, :audit_logger

    def adapter(provider, temple:)
      provider_resolver.resolve(provider: provider, temple: temple)
    end

    def latest_payment_for!(registration:, provider:)
      registration.temple_payments.where(provider: provider).order(created_at: :desc).first ||
        raise(ActiveRecord::RecordNotFound, "Payment not found")
    end

    def normalize_params(params)
      (params || {}).to_h.deep_stringify_keys
    end

    def provider_reference_for_query(payment:, params:)
      payment.provider_reference.presence ||
        params["order_id"].presence ||
        params["transaction_id"].presence ||
        payment.id.to_s
    end

    def adapter_metadata(registration:, payment:, params:)
      {
        registration_reference: registration.reference_code,
        transaction_id: params["transaction_id"],
        order_id: params["order_id"],
        payment_id: payment.id
      }.compact
    end

    def log_reconciliation_event!(registration:, payment:, provider:, previous_status:, return_params:)
      audit_logger.log!(
        action: "system.payments.reconciled",
        target: payment,
        metadata: {
          actor_type: "system",
          registration_reference: registration.reference_code,
          payment_id: payment.id,
          payment_reference: payment.provider_reference.presence || payment.id,
          provider: provider.to_s,
          source: "checkout_return",
          previous_status: previous_status,
          current_status: payment.status,
          checkout_return: return_params.except("canceled")
        },
        temple: registration.respond_to?(:temple) ? registration.temple : nil
      )
    end
  end
end
