# frozen_string_literal: true

require "test_helper"

module PaymentGateway
  class EcpayAdapterTest < ActiveSupport::TestCase
    test "checkout builds hosted handoff payload" do
      with_env(
        "ECPAY_MERCHANT_ID" => "2000132",
        "ECPAY_HASH_KEY" => "5294y06JbISpM5x9",
        "ECPAY_HASH_IV" => "v77hoKGq4kWxNNIS",
        "ECPAY_ENVIRONMENT" => "stage"
      ) do
        payload = EcpayAdapter.new.checkout(
          intent: "registration:123",
          amount_cents: 500,
          currency: "TWD",
          metadata: {
            return_url: "https://example.test/return",
            cancel_url: "https://example.test/cancel",
            webhook_url: "https://example.test/webhooks/ecpay",
            item_name: "Temple Registration",
            registration_reference: "REG-123",
            temple_slug: "shengfukung-wenfu"
          },
          idempotency_key: "idem-123"
        )

        assert_equal "pending", payload[:status]
        assert_equal "/payments/ecpay_checkouts/#{payload[:provider_reference]}", payload[:redirect_url]
        assert_equal "https://payment-stage.ecpay.com.tw/Cashier/AioCheckOut/V5", payload.dig(:raw, :ecpay_checkout_url)
        assert_equal "2000132", payload.dig(:raw, :ecpay_form_fields, "MerchantID")
        assert_equal "https://example.test/webhooks/ecpay", payload.dig(:raw, :ecpay_form_fields, "ReturnURL")
        assert_equal "https://example.test/return", payload.dig(:raw, :ecpay_form_fields, "OrderResultURL")
        assert payload.dig(:raw, :ecpay_form_fields, "CheckMacValue").present?
      end
    end

    test "ingest_webhook validates check mac and marks success" do
      with_env(
        "ECPAY_MERCHANT_ID" => "2000132",
        "ECPAY_HASH_KEY" => "5294y06JbISpM5x9",
        "ECPAY_HASH_IV" => "v77hoKGq4kWxNNIS"
      ) do
        fields = {
          "MerchantID" => "2000132",
          "MerchantTradeNo" => "TM1234567890ABCD",
          "RtnCode" => "1",
          "RtnMsg" => "Succeeded",
          "TradeNo" => "2404071234567890",
          "TradeAmt" => "500",
          "TradeStatus" => "1",
          "PaymentType" => "Credit_CreditCard",
          "CheckMacValue" => ""
        }
        fields["CheckMacValue"] = Payments::Taiwan::EcpayChecksum.generate(
          fields: fields,
          hash_key: ENV.fetch("ECPAY_HASH_KEY"),
          hash_iv: ENV.fetch("ECPAY_HASH_IV")
        )

        result = EcpayAdapter.new.ingest_webhook(payload: fields, headers: {})

        assert_equal true, result[:signature_valid]
        assert_equal "completed", result[:status]
        assert_equal "TM1234567890ABCD", result[:provider_reference]
        assert_equal "2404071234567890", result[:provider_event_id]
      end
    end

    test "checkout prefers temple-specific credentials over shared env defaults" do
      temple = create_temple(
        payment_provider_settings: {
          "ecpay" => {
            "merchant_id" => "3002607",
            "hash_key" => "TempleHashKey",
            "hash_iv" => "TempleHashIv",
            "environment" => "production"
          }
        }
      )

      with_env(
        "ECPAY_MERCHANT_ID" => "2000132",
        "ECPAY_HASH_KEY" => "5294y06JbISpM5x9",
        "ECPAY_HASH_IV" => "v77hoKGq4kWxNNIS",
        "ECPAY_ENVIRONMENT" => "stage"
      ) do
        payload = EcpayAdapter.new(temple: temple).checkout(
          intent: "registration:123",
          amount_cents: 500,
          currency: "TWD",
          metadata: {
            return_url: "https://example.test/return",
            cancel_url: "https://example.test/cancel",
            webhook_url: "https://example.test/webhooks/ecpay",
            item_name: "Temple Registration"
          },
          idempotency_key: "idem-123"
        )

        assert_equal "https://payment.ecpay.com.tw/Cashier/AioCheckOut/V5", payload.dig(:raw, :ecpay_checkout_url)
        assert_equal "3002607", payload.dig(:raw, :ecpay_form_fields, "MerchantID")
      end
    end

    private

    def with_env(overrides)
      original = overrides.transform_values { |_,| nil }
      overrides.each_key { |key| original[key] = ENV[key] }
      overrides.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
      yield
    ensure
      original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    end
  end
end
