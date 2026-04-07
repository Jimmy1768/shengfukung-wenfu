# frozen_string_literal: true

require "securerandom"

module PaymentGateway
  class EcpayAdapter < Adapter
    ConfigurationError = Class.new(StandardError)

    STAGE_CHECKOUT_URL = "https://payment-stage.ecpay.com.tw/Cashier/AioCheckOut/V5"
    PRODUCTION_CHECKOUT_URL = "https://payment.ecpay.com.tw/Cashier/AioCheckOut/V5"

    def initialize(temple: nil, routes: Rails.application.routes.url_helpers)
      @temple = temple
      @routes = routes
    end

    def verify_webhook_signature(payload:, headers:)
      ensure_configured!
      sanitized_payload = payload.to_h.except(:_raw_body, "_raw_body")

      valid = Payments::Taiwan::EcpayChecksum.valid?(
        fields: sanitized_payload,
        hash_key: credential_for(:hash_key),
        hash_iv: credential_for(:hash_iv)
      )

      { valid: valid, reason: valid ? "verified" : "check_mac_mismatch" }
    rescue ConfigurationError => e
      { valid: false, reason: e.message }
    end

    def checkout(intent:, amount_cents:, currency:, metadata:, idempotency_key:)
      ensure_configured!

      merchant_trade_no = default_trade_no(intent)
      fields = {
        "MerchantID" => credential_for(:merchant_id),
        "MerchantTradeNo" => merchant_trade_no,
        "MerchantTradeDate" => Time.current.strftime("%Y/%m/%d %H:%M:%S"),
        "PaymentType" => "aio",
        "TotalAmount" => amount_cents.to_f.round.to_i.to_s,
        "TradeDesc" => truncate(metadata_value(metadata, "item_name").presence || "Temple registration payment", 200),
        "ItemName" => truncate(metadata_value(metadata, "item_name").presence || "Temple registration payment", 400),
        "ReturnURL" => ecpay_server_callback_url(metadata),
        "OrderResultURL" => ecpay_browser_return_url(metadata),
        "ChoosePayment" => ENV.fetch("ECPAY_CHOOSE_PAYMENT", "ALL"),
        "NeedExtraPaidInfo" => "Y",
        "EncryptType" => "1"
      }
      fields["ClientBackURL"] = metadata_value(metadata, "cancel_url") if metadata_value(metadata, "cancel_url").present?
      fields["CustomField1"] = metadata_value(metadata, "registration_reference").to_s if metadata_value(metadata, "registration_reference").present?
      fields["CustomField2"] = metadata_value(metadata, "temple_slug").to_s if metadata_value(metadata, "temple_slug").present?
      fields["CheckMacValue"] = Payments::Taiwan::EcpayChecksum.generate(
        fields: fields,
        hash_key: credential_for(:hash_key),
        hash_iv: credential_for(:hash_iv)
      )

      {
        status: "pending",
        provider_checkout_id: merchant_trade_no,
        provider_payment_id: merchant_trade_no,
        provider_reference: merchant_trade_no,
        redirect_url: routes.payments_ecpay_checkout_path(payment_reference: merchant_trade_no),
        raw: {
          ecpay_checkout_url: checkout_endpoint,
          ecpay_form_fields: fields
        }
      }
    end

    def ingest_webhook(payload:, headers:)
      signature = verify_webhook_signature(payload: payload, headers: headers)
      normalized = normalize_payload(payload)

      {
        event_type: "ecpay.server_callback",
        provider_event_id: normalized[:provider_charge_id] || normalized[:provider_reference],
        provider_reference: normalized[:provider_reference],
        status: normalized[:status],
        signature_valid: signature[:valid],
        signature_reason: signature[:reason],
        raw: payload.to_h.deep_stringify_keys
      }
    end

    def confirm(provider_payment_ref:, amount_cents: nil, currency: nil, metadata: {}, idempotency_key:)
      query_status(provider_payment_ref: provider_payment_ref, metadata: metadata)
    end

    def query_status(provider_payment_ref:, metadata: {})
      normalized = normalize_payload(metadata)

      {
        status: normalized[:status],
        provider_reference: normalized[:provider_reference].presence || provider_payment_ref.to_s,
        raw: {
          ecpay_result: metadata.to_h.deep_stringify_keys
        }
      }
    end

    def refund(payment_reference:, amount_cents: nil, reason: nil, idempotency_key:)
      raise NotImplementedError, "ECPay refund flow is not yet implemented in this repo"
    end

    def cancel(payment_reference:, reason: nil, idempotency_key:)
      raise NotImplementedError, "ECPay cancel flow is not yet implemented in this repo"
    end

    private

    attr_reader :routes, :temple

    def ensure_configured!
      raise ConfigurationError, "ECPAY_MERCHANT_ID is missing" if credential_for(:merchant_id).blank?
      raise ConfigurationError, "ECPAY_HASH_KEY is missing" if credential_for(:hash_key).blank?
      raise ConfigurationError, "ECPAY_HASH_IV is missing" if credential_for(:hash_iv).blank?
    end

    # ECPay ReturnURL is the required server-to-server callback endpoint.
    def ecpay_server_callback_url(metadata)
      metadata_value(metadata, "server_callback_url").presence ||
        metadata_value(metadata, "webhook_url").presence ||
        raise(ConfigurationError, "ECPay checkout requires server_callback_url")
    end

    # ECPay OrderResultURL is the optional browser/client return page.
    def ecpay_browser_return_url(metadata)
      metadata_value(metadata, "browser_return_url").presence ||
        metadata_value(metadata, "return_url").presence ||
        raise(ConfigurationError, "ECPay checkout requires browser_return_url")
    end

    def checkout_endpoint
      ecpay_environment == "production" ? PRODUCTION_CHECKOUT_URL : STAGE_CHECKOUT_URL
    end

    def credential_for(key)
      temple&.payment_gateway_settings_for(:ecpay)&.dig(key.to_s).presence ||
        ENV.fetch("ECPAY_#{key.to_s.upcase}", nil).to_s.presence
    end

    def ecpay_environment
      temple&.payment_gateway_settings_for(:ecpay)&.dig("environment").presence ||
        Rails.configuration.x.ecpay.environment.to_s
    end

    def metadata_value(metadata, key)
      (metadata || {}).to_h.with_indifferent_access[key]
    end

    def default_trade_no(intent)
      base = intent.to_s.gsub(/[^A-Za-z0-9]/, "").upcase
      "TM#{base.last(12)}#{Time.current.strftime('%m%d%H%M%S')}#{SecureRandom.hex(2).upcase}"[0, 20]
    end

    def normalize_payload(payload)
      raw = payload.to_h.deep_stringify_keys
      rtn_code = raw["RtnCode"].to_s
      trade_status = raw["TradeStatus"].to_s

      status =
        if rtn_code == "1" && trade_status.in?(["", "1"])
          "completed"
        elsif rtn_code.present?
          "failed"
        else
          "pending"
        end

      {
        status: status,
        provider_reference: raw["MerchantTradeNo"].presence || raw["transaction_id"].presence || raw["order_id"].presence,
        provider_charge_id: raw["TradeNo"].presence
      }
    end

    def truncate(value, max_length)
      value.to_s.mb_chars.limit(max_length).to_s
    end
  end
end
