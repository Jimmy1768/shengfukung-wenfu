# frozen_string_literal: true

require "test_helper"
require "base64"
require "json"
require "openssl"

module PaymentGateway
  class LinePayAdapterTest < ActiveSupport::TestCase
    FakeResponse = Struct.new(:code, :body)

    class FakeHttpClient
      def initialize(responses)
        @responses = responses.dup
      end

      def start(_host, _port, use_ssl:)
        connection = Object.new
        responses = @responses
        connection.define_singleton_method(:request) do |_request|
          responses.shift || raise("No stubbed response remaining")
        end
        yield connection
      end
    end

    test "checkout returns normalized pending payload" do
      response_body = {
        returnCode: "0000",
        info: {
          paymentAccessToken: "token_123",
          transactionId: "tx_123",
          paymentUrl: { web: "https://pay.line.me/checkout/tx_123" }
        }
      }.to_json

      adapter = LinePayAdapter.new(http_client: FakeHttpClient.new([FakeResponse.new("200", response_body)]))
      with_env(line_env.merge("LINE_PAY_CONFIRM_BASE_URL" => "https://example.com/line/confirm")) do
        result = adapter.checkout(
          intent: "registration:1",
          amount_cents: 600,
          currency: "TWD",
          metadata: { item_name: "Lantern Registration" },
          idempotency_key: "idem_line_1"
        )

        assert_equal "pending", result[:status]
        assert_equal "tx_123", result[:provider_reference]
        assert_equal "https://pay.line.me/checkout/tx_123", result[:redirect_url]
      end
    end

    test "confirm maps successful return code to completed" do
      response_body = { returnCode: "0000", info: { transactionId: "tx_999" } }.to_json
      adapter = LinePayAdapter.new(http_client: FakeHttpClient.new([FakeResponse.new("200", response_body)]))

      with_env(line_env) do
        result = adapter.confirm(
          provider_payment_ref: "tx_999",
          amount_cents: 900,
          currency: "TWD",
          metadata: {},
          idempotency_key: "idem_line_confirm"
        )
        assert_equal "completed", result[:status]
        assert_equal "tx_999", result[:provider_reference]
      end
    end

    test "query_status maps payStatus paid to completed" do
      response_body = { returnCode: "0000", info: { transactionId: "tx_abc", payStatus: "PAID" } }.to_json
      adapter = LinePayAdapter.new(http_client: FakeHttpClient.new([FakeResponse.new("200", response_body)]))

      with_env(line_env) do
        result = adapter.query_status(provider_payment_ref: "order_abc", metadata: {})
        assert_equal "completed", result[:status]
        assert_equal "tx_abc", result[:provider_reference]
      end
    end

    test "query_status falls back to order id when transaction id missing" do
      response_body = { returnCode: "0000", info: { orderId: "order_abc", payStatus: "PENDING" } }.to_json
      adapter = LinePayAdapter.new(http_client: FakeHttpClient.new([FakeResponse.new("200", response_body)]))

      with_env(line_env) do
        result = adapter.query_status(provider_payment_ref: "order_abc", metadata: {})
        assert_equal "pending", result[:status]
        assert_equal "order_abc", result[:provider_reference]
      end
    end

    test "query_status carries metadata transaction id when provider response omits ids" do
      response_body = { returnCode: "0000", info: { payStatus: "PAID" } }.to_json
      adapter = LinePayAdapter.new(http_client: FakeHttpClient.new([FakeResponse.new("200", response_body)]))

      with_env(line_env) do
        result = adapter.query_status(provider_payment_ref: "order_abc", metadata: { transaction_id: "tx_meta_1" })
        assert_equal "completed", result[:status]
        assert_equal "tx_meta_1", result[:provider_reference]
      end
    end

    test "refund and cancel return normalized statuses" do
      success = { returnCode: "0000", info: { refundTransactionId: "rf_1" } }.to_json
      adapter = LinePayAdapter.new(http_client: FakeHttpClient.new([FakeResponse.new("200", success), FakeResponse.new("200", success)]))

      with_env(line_env) do
        refund_result = adapter.refund(
          payment_reference: "tx_123",
          amount_cents: 400,
          reason: "duplicate",
          idempotency_key: "idem_refund"
        )
        assert_equal "refunded", refund_result[:status]

        cancel_result = adapter.cancel(
          payment_reference: "tx_123",
          reason: "user_cancelled",
          idempotency_key: "idem_cancel"
        )
        assert_equal "refunded", cancel_result[:status]
      end
    end

    test "verify_webhook_signature validates x-line-signature" do
      payload_body = { event_type: "line_pay.callback", transactionId: "tx_sig_1", orderId: "order_sig_1", returnCode: "0000" }.to_json
      secret = "line_secret"
      signature = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, payload_body))
      adapter = LinePayAdapter.new

      with_env(line_env.merge("LINE_PAY_CHANNEL_SECRET" => secret)) do
        result = adapter.verify_webhook_signature(
          payload: { _raw_body: payload_body },
          headers: { "x-line-signature" => signature }
        )
        assert_equal true, result[:valid]
      end
    end

    test "ingest_webhook maps transaction status fallback when return code missing" do
      payload_body = {
        event_type: "line_pay.callback",
        transactionId: "tx_pending_1",
        orderId: "order_pending_1",
        transactionStatus: "AUTHORIZED"
      }.to_json
      secret = "line_secret"
      signature = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, payload_body))
      adapter = LinePayAdapter.new

      with_env(line_env.merge("LINE_PAY_CHANNEL_SECRET" => secret)) do
        result = adapter.ingest_webhook(
          payload: JSON.parse(payload_body).deep_symbolize_keys.merge(_raw_body: payload_body),
          headers: { "x-line-signature" => signature }
        )

        assert_equal "completed", result[:status]
        assert_equal "tx_pending_1", result[:provider_reference]
        assert_equal true, result[:signature_valid]
      end
    end

    test "confirm maps non-success return code to failed" do
      response_body = { returnCode: "1172", returnMessage: "Transaction not found" }.to_json
      adapter = LinePayAdapter.new(http_client: FakeHttpClient.new([FakeResponse.new("200", response_body)]))

      with_env(line_env) do
        result = adapter.confirm(
          provider_payment_ref: "tx_missing",
          amount_cents: 900,
          currency: "TWD",
          metadata: {},
          idempotency_key: "idem_line_confirm_fail"
        )
        assert_equal "failed", result[:status]
        assert_equal "tx_missing", result[:provider_reference]
      end
    end

    test "raises configuration error when line pay env missing" do
      adapter = LinePayAdapter.new(http_client: FakeHttpClient.new([]))

      with_env("LINE_PAY_CHANNEL_ID" => nil, "LINE_PAY_CHANNEL_SECRET" => nil, "LINE_PAY_API_BASE" => nil) do
        error = assert_raises(LinePayAdapter::ConfigurationError) do
          adapter.checkout(
            intent: "registration:missing",
            amount_cents: 600,
            currency: "TWD",
            metadata: { confirm_url: "https://example.com/ok", cancel_url: "https://example.com/cancel" },
            idempotency_key: "idem_missing"
          )
        end
        assert_includes error.message, "LINE_PAY_CHANNEL_ID"
      end
    end

    private

    def line_env
      {
        "LINE_PAY_CHANNEL_ID" => "line_channel_id",
        "LINE_PAY_CHANNEL_SECRET" => "line_channel_secret",
        "LINE_PAY_API_BASE" => "https://sandbox-api-pay.line.me"
      }
    end

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
  end
end
