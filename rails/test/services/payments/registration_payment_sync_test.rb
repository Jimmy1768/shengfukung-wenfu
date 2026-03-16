# frozen_string_literal: true

require "test_helper"

module Payments
  class RegistrationPaymentSyncTest < ActiveSupport::TestCase
    FakeRegistration = Struct.new(:payment_status) do
      attr_reader :marked_paid

      def paid?
        payment_status == TempleRegistration::PAYMENT_STATUSES[:paid]
      end

      def mark_paid!
        @marked_paid = true
        self.payment_status = TempleRegistration::PAYMENT_STATUSES[:paid]
      end

      def update!(attrs)
        self.payment_status = attrs[:payment_status] if attrs[:payment_status]
      end
    end

    FakePayment = Struct.new(:status, :temple_registration)

    test "marks registration paid on completed payment" do
      registration = FakeRegistration.new(TempleRegistration::PAYMENT_STATUSES[:pending])
      RegistrationPaymentSync.call(FakePayment.new(TemplePayment::STATUSES[:completed], registration))

      assert_equal TempleRegistration::PAYMENT_STATUSES[:paid], registration.payment_status
      assert_equal true, registration.marked_paid
    end

    test "marks registration refunded on refunded payment" do
      registration = FakeRegistration.new(TempleRegistration::PAYMENT_STATUSES[:paid])
      RegistrationPaymentSync.call(FakePayment.new(TemplePayment::STATUSES[:refunded], registration))

      assert_equal TempleRegistration::PAYMENT_STATUSES[:refunded], registration.payment_status
    end

    test "marks registration failed on failed payment" do
      registration = FakeRegistration.new(TempleRegistration::PAYMENT_STATUSES[:pending])
      RegistrationPaymentSync.call(FakePayment.new(TemplePayment::STATUSES[:failed], registration))

      assert_equal TempleRegistration::PAYMENT_STATUSES[:failed], registration.payment_status
    end
  end
end
