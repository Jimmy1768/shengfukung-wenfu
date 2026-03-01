# frozen_string_literal: true

require "base64"
require "json"
require "net/http"
require "openssl"
require "securerandom"
require "uri"

module PaymentGateway
  class LinePayAdapter < Adapter
    ConfigurationError = Class.new(StandardError)

    def initialize(http_client: Net::HTTP)
      @http_client = http_client
    end

    def verify_webhook_signature(payload:, headers:)
      signature = headers["x-line-signature"].presence || headers["X-Line-Signature"].presence
      signature = signature.to_s
      secret = ENV["LINE_PAY_CHANNEL_SECRET"].to_s

      return { valid: false, reason: "missing_signature_header" } if signature.blank?
      return { valid: false, reason: "missing_channel_secret" } if secret.blank?
      return { valid: false, reason: "missing_raw_body" } if raw_body(payload).blank?

      digest = OpenSSL::HMAC.digest("SHA256", secret, raw_body(payload))
      expected = Base64.strict_encode64(digest)
      valid = secure_compare(expected, signature)
      { valid: valid, reason: valid ? "verified" : "signature_mismatch" }
    end

    def checkout(intent:, amount_cents:, currency:, metadata:, idempotency_key:)
      ensure_configured!

      order_id = metadata_value(metadata, "line_pay_order_id").presence || default_order_id(intent)
      amount = cents_to_major(amount_cents)
      confirm_url = line_pay_confirm_url(metadata)
      cancel_url = line_pay_cancel_url(metadata)
      raise ConfigurationError, "LINE Pay checkout requires confirm_url or LINE_PAY_CONFIRM_BASE_URL" if confirm_url.blank?
      raise ConfigurationError, "LINE Pay checkout requires cancel_url or LINE_PAY_CONFIRM_BASE_URL" if cancel_url.blank?

      request_body = {
        amount: amount,
        currency: normalized_currency(currency),
        orderId: order_id,
        packages: [
          {
            id: metadata_value(metadata, "package_id").presence || "default_package",
            amount: amount,
            name: metadata_value(metadata, "package_name").presence || "TempleMate Payment",
            products: [
              {
                id: metadata_value(metadata, "product_id").presence || "registration",
                name: metadata_value(metadata, "item_name").presence || "Registration",
                quantity: 1,
                price: amount
              }
            ]
          }
        ],
        redirectUrls: {
          confirmUrl: confirm_url,
          cancelUrl: cancel_url
        }
      }

      response = request_line_pay(
        method: :post,
        path: "/v3/payments/request",
        body: request_body
      )

      info = response["info"] || {}
      {
        status: "pending",
        provider_checkout_id: info["paymentAccessToken"],
        provider_payment_id: info["transactionId"]&.to_s,
        provider_reference: info["transactionId"]&.to_s || order_id,
        redirect_url: info.dig("paymentUrl", "web"),
        checkout_mode: "line_pay",
        raw: {
          line_pay_response: response
        }
      }
    end

    def ingest_webhook(payload:, headers:)
      signature = verify_webhook_signature(payload: payload, headers: headers)
      normalized = normalize_webhook_payload(payload)
      {
        event_type: normalized[:event_type],
        provider_event_id: normalized[:provider_event_id],
        provider_reference: normalized[:provider_reference],
        status: normalized[:status],
        signature_valid: signature[:valid],
        signature_reason: signature[:reason],
        raw: {
          payload: payload.deep_dup,
          headers: headers.slice("x-line-signature", "X-Line-Signature")
        }
      }
    end

    def confirm(provider_payment_ref:, amount_cents: nil, currency: nil, metadata: {}, idempotency_key:)
      ensure_configured!
      raise ArgumentError, "amount_cents is required for LINE Pay confirm" if amount_cents.blank?
      raise ArgumentError, "currency is required for LINE Pay confirm" if currency.blank?

      transaction_id = provider_payment_ref.to_s
      response = request_line_pay(
        method: :post,
        path: "/v3/payments/#{transaction_id}/confirm",
        body: {
          amount: cents_to_major(amount_cents),
          currency: normalized_currency(currency)
        }
      )

      {
        status: line_return_code_success?(response["returnCode"]) ? "completed" : "failed",
        provider_reference: transaction_id,
        raw: {
          line_pay_response: response,
          metadata: metadata
        }
      }
    end

    def query_status(provider_payment_ref:, metadata: {})
      ensure_configured!
      order_id = provider_payment_ref.to_s
      path = "/v3/payments/requests/#{order_id}/check"
      transaction_id = metadata_value(metadata, "transaction_id")
      path = "#{path}?transactionId=#{URI.encode_www_form_component(transaction_id.to_s)}" if transaction_id.present?

      response = request_line_pay(method: :get, path: path)
      info = response["info"] || {}
      {
        status: map_check_status(info["payStatus"] || info["transactionStatus"]),
        provider_reference: info["transactionId"]&.to_s || order_id,
        raw: {
          line_pay_response: response
        }
      }
    end

    def refund(payment_reference:, amount_cents: nil, reason: nil, idempotency_key:)
      ensure_configured!
      transaction_id = payment_reference.to_s
      body = {}
      body[:refundAmount] = cents_to_major(amount_cents) if amount_cents.present?

      response = request_line_pay(
        method: :post,
        path: "/v3/payments/#{transaction_id}/refund",
        body: body
      )

      {
        status: line_return_code_success?(response["returnCode"]) ? "refunded" : "failed",
        provider_reference: transaction_id,
        raw: {
          line_pay_response: response,
          reason: reason
        }
      }
    end

    def cancel(payment_reference:, reason: nil, idempotency_key:)
      refund(payment_reference: payment_reference, reason: reason, idempotency_key: idempotency_key)
    end

    private

    attr_reader :http_client

    def ensure_configured!
      raise ConfigurationError, "LINE_PAY_CHANNEL_ID is missing" if ENV["LINE_PAY_CHANNEL_ID"].to_s.blank?
      raise ConfigurationError, "LINE_PAY_CHANNEL_SECRET is missing" if ENV["LINE_PAY_CHANNEL_SECRET"].to_s.blank?
      raise ConfigurationError, "LINE_PAY_API_BASE is missing" if ENV["LINE_PAY_API_BASE"].to_s.blank?
    end

    def line_pay_confirm_url(metadata)
      metadata_value(metadata, "confirm_url").presence || ENV["LINE_PAY_CONFIRM_BASE_URL"].to_s
    end

    def line_pay_cancel_url(metadata)
      metadata_value(metadata, "cancel_url").presence || ENV["LINE_PAY_CONFIRM_BASE_URL"].to_s
    end

    def request_line_pay(method:, path:, body: nil)
      uri = URI.parse("#{ENV.fetch('LINE_PAY_API_BASE')}#{path}")
      nonce = SecureRandom.uuid
      request_body = body.nil? ? "" : JSON.generate(body)
      request_uri = uri.request_uri

      request = build_request(method, uri, request_body)
      request["X-LINE-ChannelId"] = ENV.fetch("LINE_PAY_CHANNEL_ID")
      request["X-LINE-Authorization-Nonce"] = nonce
      request["X-LINE-Authorization"] = line_authorization_header(request_uri: request_uri, request_body: request_body, nonce: nonce)

      response = http_client.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      parsed = response.body.present? ? JSON.parse(response.body) : {}
      return parsed if response.code.to_i.between?(200, 299)

      raise ConfigurationError, "LINE Pay API error #{response.code}: #{parsed['returnMessage'] || response.body}"
    end

    def build_request(method, uri, request_body)
      case method.to_sym
      when :post
        req = Net::HTTP::Post.new(uri)
        req["Content-Type"] = "application/json"
        req.body = request_body
        req
      when :get
        Net::HTTP::Get.new(uri)
      else
        raise ArgumentError, "Unsupported HTTP method: #{method}"
      end
    end

    def line_authorization_header(request_uri:, request_body:, nonce:)
      secret = ENV.fetch("LINE_PAY_CHANNEL_SECRET")
      message = "#{secret}#{request_uri}#{request_body}#{nonce}"
      digest = OpenSSL::HMAC.digest("SHA256", secret, message)
      Base64.strict_encode64(digest)
    end

    def normalize_webhook_payload(payload)
      return_code = payload[:returnCode].presence || payload["returnCode"].presence
      transaction_id = payload[:transactionId].presence || payload["transactionId"].presence
      order_id = payload[:orderId].presence || payload["orderId"].presence
      event_type = payload[:event_type].presence || payload["event_type"].presence || "line_pay.callback"

      status =
        if line_return_code_success?(return_code)
          "completed"
        elsif return_code.present?
          "failed"
        else
          "pending"
        end

      {
        event_type: event_type,
        provider_event_id: transaction_id || order_id,
        provider_reference: transaction_id || order_id,
        status: status
      }
    end

    def map_check_status(value)
      case value.to_s.downcase
      when "paid", "completed", "capture", "authorized"
        "completed"
      when "cancel", "cancelled", "failed", "void"
        "failed"
      else
        "pending"
      end
    end

    def line_return_code_success?(return_code)
      return_code.to_s == "0000"
    end

    def normalized_currency(currency)
      currency.to_s.upcase
    end

    def cents_to_major(cents)
      (cents.to_i / 100.0).round(2)
    end

    def metadata_value(metadata, key)
      (metadata || {}).to_h.with_indifferent_access[key]
    end

    def raw_body(payload)
      payload[:_raw_body].presence || payload["_raw_body"].presence
    end

    def default_order_id(intent)
      "line_#{intent.to_s.parameterize(separator: '_')}_#{SecureRandom.hex(4)}"
    end

    def secure_compare(a, b)
      return false if a.blank? || b.blank?
      return false unless a.bytesize == b.bytesize

      ActiveSupport::SecurityUtils.secure_compare(a, b)
    end
  end
end
