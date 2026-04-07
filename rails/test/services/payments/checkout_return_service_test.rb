# frozen_string_literal: true

require "test_helper"

module Payments
  class CheckoutReturnServiceTest < ActiveSupport::TestCase
    FakeAuditLogger = Struct.new(:calls) do
      def log!(**kwargs)
        calls << kwargs
      end
    end

    FakeTemple = Struct.new(:id)
    FakeRegistration = Struct.new(:reference_code, :payment_status, :temple) do
      def paid?
        payment_status == TempleRegistration::PAYMENT_STATUSES[:paid]
      end

      def mark_paid!
        self.payment_status = TempleRegistration::PAYMENT_STATUSES[:paid]
      end

      def update!(attrs)
        self.payment_status = attrs[:payment_status] if attrs[:payment_status]
      end
    end

    FakePayment = Struct.new(
      :id,
      :status,
      :provider_reference,
      :amount_cents,
      :currency,
      :payment_payload,
      :metadata,
      :temple_registration,
      keyword_init: true
    ) do
      def completed?
        status == TemplePayment::STATUSES[:completed]
      end

      def failed?
        status == TemplePayment::STATUSES[:failed]
      end
    end

    class FakeAdapter
      attr_reader :confirm_calls, :query_calls

      def initialize(confirm_status: "completed", query_status: "pending")
        @confirm_status = confirm_status
        @query_status = query_status
        @confirm_calls = []
        @query_calls = []
      end

      def confirm(**kwargs)
        @confirm_calls << kwargs
        { status: @confirm_status, provider_reference: kwargs[:provider_payment_ref], raw: {} }
      end

      def query_status(**kwargs)
        @query_calls << kwargs
        { status: @query_status, provider_reference: kwargs[:provider_payment_ref], raw: {} }
      end
    end

    class FakeResolver
      def initialize(adapter)
        @adapter = adapter
      end

      def resolve(provider:, **)
        @adapter
      end
    end

    class FakeRepository
      attr_reader :updated_attrs

      def initialize(payment)
        @payment = payment
      end

      def update_status!(payment:, status:, payload:, metadata:, provider_reference: nil)
        @updated_attrs = {
          payment: payment,
          status: status,
          payload: payload,
          metadata: metadata,
          provider_reference: provider_reference
        }
        payment.status = status
        payment.provider_reference = provider_reference if provider_reference.present?
        payment.payment_payload = payload
        payment.metadata = metadata
        payment
      end
    end

    test "ecpay return queries payment status using callback payload" do
      registration = FakeRegistration.new("REG-123", TempleRegistration::PAYMENT_STATUSES[:pending], FakeTemple.new(1))
      payment = FakePayment.new(
        id: 9,
        status: TemplePayment::STATUSES[:pending],
        provider_reference: "order_123",
        amount_cents: 1200,
        currency: "TWD",
        payment_payload: {},
        metadata: {},
        temple_registration: registration
      )
      adapter = FakeAdapter.new(query_status: "completed")
      repository = FakeRepository.new(payment)
      audit_logger = FakeAuditLogger.new([])
      registration.define_singleton_method(:temple_payments) { TemplePayment.none }
      service = CheckoutReturnService.new(provider_resolver: FakeResolver.new(adapter), payment_repository: repository, audit_logger: audit_logger)
      service.stub(:latest_payment_for!, payment) do
        result = service.call(
          registration: registration,
          provider: "ecpay",
          params: { transaction_id: "tx_123", order_id: "order_123" }
        )

        assert_equal TemplePayment::STATUSES[:completed], result.payment.status
        assert_equal "order_123", result.payment.provider_reference
        assert_equal TempleRegistration::PAYMENT_STATUSES[:paid], registration.payment_status
        assert_equal 0, adapter.confirm_calls.length
        assert_equal 1, adapter.query_calls.length
        assert_includes audit_logger.calls.map { |call| call[:action] }, "system.registrations.payment_status_updated"
        assert_includes audit_logger.calls.map { |call| call[:action] }, "system.payments.reconciled"
      end
    end

    test "fake provider return queries status" do
      registration = FakeRegistration.new("REG-321", TempleRegistration::PAYMENT_STATUSES[:pending], FakeTemple.new(1))
      payment = FakePayment.new(
        id: 10,
        status: TemplePayment::STATUSES[:pending],
        provider_reference: "fake_ref_123",
        amount_cents: 1600,
        currency: "TWD",
        payment_payload: {},
        metadata: {},
        temple_registration: registration
      )
      adapter = FakeAdapter.new(query_status: "pending")
      repository = FakeRepository.new(payment)
      audit_logger = FakeAuditLogger.new([])
      registration.define_singleton_method(:temple_payments) { TemplePayment.none }
      service = CheckoutReturnService.new(provider_resolver: FakeResolver.new(adapter), payment_repository: repository, audit_logger: audit_logger)
      service.stub(:latest_payment_for!, payment) do
        result = service.call(
          registration: registration,
          provider: "fake",
          params: {}
        )

        assert_equal TemplePayment::STATUSES[:pending], result.payment.status
        assert_equal 0, adapter.confirm_calls.length
        assert_equal 1, adapter.query_calls.length
        assert_includes audit_logger.calls.map { |call| call[:action] }, "system.payments.reconciled"
      end
    end
  end
end
