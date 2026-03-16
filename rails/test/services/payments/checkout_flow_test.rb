# frozen_string_literal: true

require "test_helper"

module Payments
  class CheckoutFlowTest < ActiveSupport::TestCase
    FakeRegistration = Struct.new(:reference_code)
    FakeResult = Struct.new(:adapter_payload, :payment)
    FakePayment = Struct.new(:payment_payload)

    test "builds normalized checkout metadata" do
      metadata = CheckoutFlow.metadata_for(
        registration: FakeRegistration.new("REG-123"),
        source: "account_portal",
        temple_slug: "shengfukung-wenfu",
        return_url: "https://example.com/return",
        cancel_url: "https://example.com/cancel"
      )

      assert_equal "account_portal", metadata[:source]
      assert_equal "shengfukung-wenfu", metadata[:temple_slug]
      assert_equal "REG-123", metadata[:registration_reference]
      assert_equal "https://example.com/return", metadata[:return_url]
      assert_equal "https://example.com/return", metadata[:confirm_url]
      assert_equal "https://example.com/cancel", metadata[:cancel_url]
    end

    test "extracts provider reference from normalized adapter payload" do
      assert_equal "pay_ref", CheckoutFlow.provider_reference_for({ provider_reference: "pay_ref" })
      assert_equal "payment_id", CheckoutFlow.provider_reference_for({ provider_payment_id: "payment_id" })
      assert_equal "checkout_id", CheckoutFlow.provider_reference_for({ provider_checkout_id: "checkout_id" })
    end

    test "extracts redirect url from result payloads" do
      result = FakeResult.new({ redirect_url: "https://pay.example.test/checkout" }, FakePayment.new({}))
      assert_equal "https://pay.example.test/checkout", CheckoutFlow.redirect_url_for(result)

      fallback_result = FakeResult.new({}, FakePayment.new({ "redirect_url" => "https://pay.example.test/fallback" }))
      assert_equal "https://pay.example.test/fallback", CheckoutFlow.redirect_url_for(fallback_result)
    end
  end
end
