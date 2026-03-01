# frozen_string_literal: true

module Payments
  module Repositories
    class PaymentRepository
      def find_by_idempotency(temple:, provider:, idempotency_key:)
        return nil if idempotency_key.blank?

        temple.temple_payments.find_by(provider: provider, idempotency_key: idempotency_key)
      end

      def find_by_provider_reference(temple:, provider:, provider_reference:)
        return nil if provider_reference.blank?

        temple.temple_payments.find_by(provider: provider, provider_reference: provider_reference)
      end

      def find_completed_by_intent(temple:, intent_key:)
        return nil if intent_key.blank?

        temple.temple_payments.completed.find_by(intent_key: intent_key)
      end

      def create_pending!(registration:, provider:, provider_account:, payment_method:, amount_cents:, currency:, idempotency_key:, intent_key:, metadata: {})
        registration.temple_payments.create!(
          temple: registration.temple,
          user: registration.user,
          provider: provider,
          provider_account: provider_account,
          payment_method: payment_method,
          status: TemplePayment::STATUSES[:pending],
          amount_cents: amount_cents,
          currency: currency,
          idempotency_key: idempotency_key,
          intent_key: intent_key,
          metadata: normalize_metadata(metadata)
        )
      end

      def apply_checkout_result!(payment:, status:, provider_reference:, payload: {}, metadata: {})
        Payments::StatusTransitionPolicy.assert!(from: payment.status, to: status)

        attrs = {
          status: status,
          provider_reference: provider_reference,
          payment_payload: sanitize_for_audit(payload),
          metadata: normalize_metadata(payment.metadata).merge(normalize_metadata(metadata))
        }
        attrs[:processed_at] = Time.current if status == TemplePayment::STATUSES[:completed]
        payment.update!(attrs)
        payment
      end

      def update_status!(payment:, status:, payload: {}, metadata: {}, provider_reference: nil)
        Payments::StatusTransitionPolicy.assert!(from: payment.status, to: status)

        attrs = {
          status: status,
          payment_payload: sanitize_for_audit(payload),
          metadata: normalize_metadata(payment.metadata).merge(normalize_metadata(metadata))
        }
        attrs[:provider_reference] = provider_reference if provider_reference.present?
        attrs[:processed_at] = Time.current if status == TemplePayment::STATUSES[:completed]
        attrs[:refunded_at] = Time.current if status == TemplePayment::STATUSES[:refunded]
        payment.update!(attrs)
        payment
      end

      private

      def sanitize_for_audit(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, val), result|
            key_str = key.to_s
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

      def normalize_metadata(value)
        return {} if value.blank?

        value.to_h.deep_stringify_keys
      end
    end
  end
end
