# frozen_string_literal: true

require "test_helper"
require "ostruct"

module PaymentGateway
  class StripeAdapterTest < ActiveSupport::TestCase
    test "payment_intent checkout returns client_secret payload" do
      with_stubbed_stripe do
        with_env("STRIPE_SECRET_KEY" => "sk_test_123", "STRIPE_WEBHOOK_SECRET" => "whsec_123") do
          result = StripeAdapter.new.checkout(
            intent: "registration:1",
            amount_cents: 1200,
            currency: "TWD",
            metadata: { checkout_mode: "payment_intent", customer_email: "user@example.com" },
            idempotency_key: "idem_pi_1"
          )

          assert_equal "pending", result[:status]
          assert_equal "pi_test_123", result[:provider_reference]
          assert_equal "secret_pi_test_123", result[:client_secret]
          assert_equal "payment_intent", result[:checkout_mode]
        end
      end
    end

    test "checkout_session mode returns redirect_url payload" do
      with_stubbed_stripe do
        with_env("STRIPE_SECRET_KEY" => "sk_test_123", "STRIPE_WEBHOOK_SECRET" => "whsec_123") do
          result = StripeAdapter.new.checkout(
            intent: "registration:2",
            amount_cents: 1800,
            currency: "TWD",
            metadata: {
              checkout_mode: "checkout_session",
              success_url: "https://example.com/success",
              cancel_url: "https://example.com/cancel",
              item_name: "Temple Registration"
            },
            idempotency_key: "idem_cs_1"
          )

          assert_equal "pending", result[:status]
          assert_equal "cs_test_123", result[:provider_checkout_id]
          assert_equal "https://checkout.stripe.test/session/cs_test_123", result[:redirect_url]
          assert_equal "checkout_session", result[:checkout_mode]
        end
      end
    end

    test "ingest_webhook maps payment_intent success event" do
      with_stubbed_stripe do
        with_env("STRIPE_SECRET_KEY" => "sk_test_123", "STRIPE_WEBHOOK_SECRET" => "whsec_123") do
          body_hash = {
            id: "evt_123",
            type: "payment_intent.succeeded",
            data: { object: { id: "pi_test_123", status: "succeeded" } }
          }
          raw_body = body_hash.to_json
          payload = body_hash.merge(_raw_body: raw_body)

          result = StripeAdapter.new.ingest_webhook(
            payload: payload,
            headers: { "Stripe-Signature" => "sig_test_123" }
          )

          assert_equal true, result[:signature_valid]
          assert_equal "payment_intent.succeeded", result[:event_type]
          assert_equal "evt_123", result[:provider_event_id]
          assert_equal "pi_test_123", result[:provider_reference]
          assert_equal "completed", result[:status]
        end
      end
    end

    test "refund and cancel return normalized statuses" do
      with_stubbed_stripe do
        with_env("STRIPE_SECRET_KEY" => "sk_test_123", "STRIPE_WEBHOOK_SECRET" => "whsec_123") do
          adapter = StripeAdapter.new

          refund_result = adapter.refund(
            payment_reference: "pi_test_123",
            amount_cents: 500,
            reason: "requested_by_customer",
            idempotency_key: "idem_refund_1"
          )
          assert_equal "refunded", refund_result[:status]

          cancel_result = adapter.cancel(
            payment_reference: "pi_test_123",
            reason: "user_cancelled",
            idempotency_key: "idem_cancel_1"
          )
          assert_equal "canceled", cancel_result[:status]
        end
      end
    end

    test "raises configuration error when stripe secret key missing" do
      with_stubbed_stripe do
        with_env("STRIPE_SECRET_KEY" => nil, "STRIPE_WEBHOOK_SECRET" => "whsec_123") do
          error = assert_raises(StripeAdapter::ConfigurationError) do
            StripeAdapter.new.checkout(
              intent: "registration:3",
              amount_cents: 500,
              currency: "TWD",
              metadata: { checkout_mode: "payment_intent" },
              idempotency_key: "idem_missing_secret"
            )
          end
          assert_includes error.message, "STRIPE_SECRET_KEY"
        end
      end
    end

    private

    def with_env(overrides)
      original = {}
      overrides.each do |key, value|
        original[key] = ENV[key]
        value.nil? ? ENV.delete(key) : ENV[key] = value
      end
      yield
    ensure
      original.each do |key, value|
        value.nil? ? ENV.delete(key) : ENV[key] = value
      end
    end

    def with_stubbed_stripe
      original = Object.const_get(:Stripe) if Object.const_defined?(:Stripe)
      Object.send(:remove_const, :Stripe) if Object.const_defined?(:Stripe)
      Object.const_set(:Stripe, build_stripe_stub)
      yield
    ensure
      Object.send(:remove_const, :Stripe) if Object.const_defined?(:Stripe)
      Object.const_set(:Stripe, original) if original
    end

    def build_stripe_stub
      module_obj = Module.new

      module_obj.singleton_class.class_eval do
        attr_accessor :api_key
      end

      event_error = Class.new(StandardError)
      module_obj.const_set(:SignatureVerificationError, event_error)

      webhook_class = Class.new do
        class << self
          def construct_event(raw_body, signature, secret)
            raise Stripe::SignatureVerificationError, "missing signature" if signature.to_s.blank?
            raise Stripe::SignatureVerificationError, "missing secret" if secret.to_s.blank?

            OpenStruct.new(JSON.parse(raw_body))
          end
        end
      end
      module_obj.const_set(:Webhook, webhook_class)

      payment_intent_class = Class.new do
        class << self
          def create(params, options = {})
            OpenStruct.new(
              id: "pi_test_123",
              status: "requires_payment_method",
              client_secret: "secret_pi_test_123",
              to_hash: params.merge("id" => "pi_test_123", "status" => "requires_payment_method")
            )
          end

          def retrieve(reference)
            OpenStruct.new(id: reference, status: "succeeded", to_hash: { "id" => reference, "status" => "succeeded" })
          end

          def cancel(reference, params = {}, options = {})
            OpenStruct.new(id: reference, status: "canceled", to_hash: { "id" => reference, "status" => "canceled" })
          end
        end
      end
      module_obj.const_set(:PaymentIntent, payment_intent_class)

      refund_class = Class.new do
        class << self
          def create(params, options = {})
            OpenStruct.new(status: "succeeded", to_hash: params.merge("status" => "succeeded"))
          end
        end
      end
      module_obj.const_set(:Refund, refund_class)

      checkout_module = Module.new
      session_class = Class.new do
        class << self
          def create(params, options = {})
            OpenStruct.new(
              id: "cs_test_123",
              payment_intent: "pi_test_123",
              url: "https://checkout.stripe.test/session/cs_test_123",
              to_hash: params.merge("id" => "cs_test_123", "payment_intent" => "pi_test_123")
            )
          end
        end
      end
      checkout_module.const_set(:Session, session_class)
      module_obj.const_set(:Checkout, checkout_module)

      module_obj
    end
  end
end
