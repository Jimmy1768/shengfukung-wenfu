# frozen_string_literal: true

require "test_helper"

module Payments
  class CheckoutServiceTest < ActiveSupport::TestCase
    FakeTemple = Struct.new(:id)
    FakeRegistration = Struct.new(:temple, :user)

    class FakeRepository
      attr_reader :completed_intent_lookup

      def initialize(existing_by_idempotency: nil, completed_for_intent: nil)
        @existing_by_idempotency = existing_by_idempotency
        @completed_for_intent = completed_for_intent
      end

      def find_by_idempotency(**)
        @existing_by_idempotency
      end

      def find_completed_by_intent(temple:, intent_key:)
        @completed_intent_lookup = [temple, intent_key]
        @completed_for_intent
      end
    end

    test "requires idempotency_key" do
      service = CheckoutService.new(payment_repository: FakeRepository.new)

      error = assert_raises(ArgumentError) do
        service.call(
          registration: FakeRegistration.new(FakeTemple.new(1), nil),
          amount_cents: 1000,
          currency: "TWD",
          provider: "fake",
          idempotency_key: nil,
          intent_key: "reg-123"
        )
      end

      assert_equal "idempotency_key is required", error.message
    end

    test "returns existing completed intent as reused" do
      existing_payment = TemplePayment.new(status: TemplePayment::STATUSES[:completed])
      repository = FakeRepository.new(completed_for_intent: existing_payment)
      service = CheckoutService.new(payment_repository: repository)

      result = service.call(
        registration: FakeRegistration.new(FakeTemple.new(1), nil),
        amount_cents: 1000,
        currency: "TWD",
        provider: "fake",
        idempotency_key: "idem-1",
        intent_key: "intent-1"
      )

      assert result.reused
      assert_equal existing_payment, result.payment
      assert_equal "duplicate_intent", result.adapter_payload[:reason]
    end
  end
end
