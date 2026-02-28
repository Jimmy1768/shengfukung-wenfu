# frozen_string_literal: true

require "test_helper"

module Payments
  class RefundServiceTest < ActiveSupport::TestCase
    class FakeAdapter
      def refund(payment_reference:, amount_cents:, reason:, idempotency_key:)
        {
          status: "refunded",
          provider_reference: payment_reference,
          raw: {
            amount_cents: amount_cents,
            reason: reason,
            idempotency_key: idempotency_key
          }
        }
      end

      def cancel(payment_reference:, reason:, idempotency_key:)
        {
          status: "canceled",
          provider_reference: payment_reference,
          raw: {
            reason: reason,
            idempotency_key: idempotency_key
          }
        }
      end
    end

    class FakeResolver
      def initialize(adapter)
        @adapter = adapter
      end

      def resolve(provider:)
        @adapter
      end
    end

    class FakeRepository
      attr_reader :updated_status, :updated_metadata

      def update_status!(payment:, status:, payload:, metadata:, provider_reference: nil)
        @updated_status = status
        @updated_metadata = metadata
        payment.status = status
        payment
      end
    end

    test "refund path maps to refunded" do
      payment = TemplePayment.new(provider: "fake", status: TemplePayment::STATUSES[:completed], provider_reference: "pay_123")
      repository = FakeRepository.new
      service = RefundService.new(provider_resolver: FakeResolver.new(FakeAdapter.new), payment_repository: repository)

      result = service.call(
        payment: payment,
        amount_cents: 500,
        reason: "duplicate",
        idempotency_key: "refund-1",
        operation: :refund
      )

      assert_equal TemplePayment::STATUSES[:refunded], repository.updated_status
      assert_equal :refund, repository.updated_metadata[:operation]
      assert_equal TemplePayment::STATUSES[:refunded], result.payment.status
    end

    test "cancel path maps to failed status with operation metadata" do
      payment = TemplePayment.new(provider: "fake", status: TemplePayment::STATUSES[:pending], provider_reference: "pay_456")
      repository = FakeRepository.new
      service = RefundService.new(provider_resolver: FakeResolver.new(FakeAdapter.new), payment_repository: repository)

      result = service.call(
        payment: payment,
        reason: "user_cancelled",
        idempotency_key: "cancel-1",
        operation: :cancel
      )

      assert_equal TemplePayment::STATUSES[:failed], repository.updated_status
      assert_equal :cancel, repository.updated_metadata[:operation]
      assert_equal TemplePayment::STATUSES[:failed], result.payment.status
    end
  end
end
