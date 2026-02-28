# frozen_string_literal: true

module Payments
  module Repositories
    class PaymentEventLogRepository
      DuplicateEvent = Class.new(StandardError)

      def record_once!(temple:, provider:, event_type:, provider_reference:, provider_event_id:, payload:, signature_valid:)
        if provider_event_id.present?
          existing = PaymentWebhookLog.find_by(provider: provider, provider_event_id: provider_event_id)
          raise DuplicateEvent, "Duplicate provider event: #{provider}/#{provider_event_id}" if existing
        end

        PaymentWebhookLog.create!(
          temple: temple,
          provider: provider,
          event_type: event_type,
          provider_reference: provider_reference.presence || provider_event_id.presence || "unknown",
          provider_event_id: provider_event_id,
          payload: payload,
          signature_valid: signature_valid,
          received_at: Time.current,
          processed: false
        )
      end

      def mark_processed!(event_log)
        event_log.update!(processed: true, processed_at: Time.current, processing_error: nil)
      end

      def mark_failed!(event_log, error)
        event_log.update!(processed: false, processing_error: error.to_s)
      end
    end
  end
end
