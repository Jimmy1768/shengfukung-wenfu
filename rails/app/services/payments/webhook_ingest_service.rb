# frozen_string_literal: true

module Payments
  class WebhookIngestService
    Result = Struct.new(:event_log, :payment, :duplicate, keyword_init: true)
    InvalidWebhookSignature = Class.new(StandardError)

    def initialize(
      provider_resolver: ProviderResolver,
      payment_repository: Repositories::PaymentRepository.new,
      event_log_repository: Repositories::PaymentEventLogRepository.new,
      audit_logger: SystemAuditLogger
    )
      @provider_resolver = provider_resolver
      @payment_repository = payment_repository
      @event_log_repository = event_log_repository
      @audit_logger = audit_logger
    end

    def call(temple:, provider:, payload:, headers: {})
      adapter_payload = adapter(provider).ingest_webhook(payload: payload, headers: headers)

      event_log = event_log_repository.record_once!(
        temple: temple,
        provider: provider,
        event_type: adapter_payload[:event_type],
        provider_reference: adapter_payload[:provider_reference],
        provider_event_id: adapter_payload[:provider_event_id],
        payload: sanitize_for_audit(adapter_payload[:raw] || payload),
        signature_valid: adapter_payload[:signature_valid]
      )

      unless adapter_payload[:signature_valid]
        raise InvalidWebhookSignature, "Invalid #{provider} webhook signature (#{adapter_payload[:signature_reason] || 'unknown'})"
      end

      payment = payment_repository.find_by_provider_reference(
        temple: temple,
        provider: provider,
        provider_reference: adapter_payload[:provider_reference]
      )

      if payment
        payment_repository.update_status!(
          payment: payment,
          status: Payments::StatusMapper.map(adapter_payload[:status]),
          payload: sanitize_for_audit(adapter_payload[:raw] || payload),
          metadata: {
            webhook_event_type: adapter_payload[:event_type],
            provider_event_id: adapter_payload[:provider_event_id],
            signature_verified: true
          },
          provider_reference: adapter_payload[:provider_reference]
        )
        Payments::RegistrationPaymentSync.call(payment)
        log_webhook_event!(
          temple: temple,
          payment: payment,
          provider: provider,
          adapter_payload: adapter_payload
        )
      end

      event_log_repository.mark_processed!(event_log)
      Result.new(event_log: event_log, payment: payment, duplicate: false)
    rescue Repositories::PaymentEventLogRepository::DuplicateEvent
      Result.new(event_log: nil, payment: nil, duplicate: true)
    rescue StandardError => e
      event_log_repository.mark_failed!(event_log, e) if event_log
      raise e
    end

    private

    attr_reader :provider_resolver, :payment_repository, :event_log_repository, :audit_logger

    def adapter(provider)
      provider_resolver.resolve(provider: provider)
    end

    def sanitize_for_audit(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, val), result|
          key_str = key.to_s
          next if key_str == "_raw_body"

          result[key] = if sensitive_key?(key_str)
                          "[FILTERED]"
                        else
                          sanitize_for_audit(val)
                        end
        end
      when Array
        value.map { |item| sanitize_for_audit(item) }
      else
        value
      end
    end

    def sensitive_key?(key)
      key.match?(/secret|token|authorization|signature|card|cvv|cvc|pan|password/i)
    end

    def log_webhook_event!(temple:, payment:, provider:, adapter_payload:)
      audit_logger.log!(
        action: "system.payments.webhook_applied",
        target: payment,
        temple: temple,
        metadata: {
          actor_type: "system",
          payment_id: payment.id,
          payment_reference: payment.provider_reference.presence || payment.id,
          registration_reference: payment.temple_registration&.reference_code,
          provider: provider.to_s,
          provider_event_id: adapter_payload[:provider_event_id],
          event_type: adapter_payload[:event_type],
          status: adapter_payload[:status]
        }.compact
      )
    end

  end
end
