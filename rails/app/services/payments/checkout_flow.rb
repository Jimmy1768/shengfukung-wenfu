# frozen_string_literal: true

module Payments
  class CheckoutFlow
    def self.metadata_for(registration:, source:, temple_slug:, return_url:, cancel_url:, extra: {})
      {
        source: source,
        temple_slug: temple_slug,
        registration_reference: registration.reference_code,
        return_url: return_url,
        confirm_url: return_url,
        cancel_url: cancel_url
      }.merge((extra || {}).deep_symbolize_keys)
    end

    def self.provider_reference_for(adapter_payload)
      return if adapter_payload.blank?

      adapter_payload[:provider_reference] ||
        adapter_payload["provider_reference"] ||
        adapter_payload[:provider_payment_id] ||
        adapter_payload["provider_payment_id"] ||
        adapter_payload[:provider_checkout_id] ||
        adapter_payload["provider_checkout_id"]
    end

    def self.redirect_url_for(result_or_payload)
      return if result_or_payload.blank?

      if result_or_payload.respond_to?(:adapter_payload)
        return redirect_url_for(result_or_payload.adapter_payload).presence ||
          redirect_url_for(result_or_payload.payment&.payment_payload)
      end

      result_or_payload[:redirect_url] || result_or_payload["redirect_url"]
    end
  end
end
