# frozen_string_literal: true

require "test_helper"

module Payments
  class RegistrationPaymentSyncTest < ActiveSupport::TestCase
    FakeAuditLogger = Struct.new(:calls) do
      def log!(**kwargs)
        calls << kwargs
      end
    end

    FakeRegistration = Struct.new(:payment_status, :reference_code, :temple) do
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

    FakePayment = Struct.new(:id, :status, :provider, :provider_reference, :temple_registration)

    test "marks registration paid on completed payment" do
      audit_logger = FakeAuditLogger.new([])
      registration = FakeRegistration.new(TempleRegistration::PAYMENT_STATUSES[:pending], "REG-1", :temple)
      RegistrationPaymentSync.call(
        FakePayment.new(1, TemplePayment::STATUSES[:completed], "fake", "pay_1", registration),
        audit_logger: audit_logger
      )

      assert_equal TempleRegistration::PAYMENT_STATUSES[:paid], registration.payment_status
      assert_equal true, registration.marked_paid
      assert_equal "system.registrations.payment_status_updated", audit_logger.calls.last[:action]
    end

    test "marks registration refunded on refunded payment" do
      audit_logger = FakeAuditLogger.new([])
      registration = FakeRegistration.new(TempleRegistration::PAYMENT_STATUSES[:paid], "REG-2", :temple)
      RegistrationPaymentSync.call(
        FakePayment.new(2, TemplePayment::STATUSES[:refunded], "fake", "pay_2", registration),
        audit_logger: audit_logger
      )

      assert_equal TempleRegistration::PAYMENT_STATUSES[:refunded], registration.payment_status
      assert_equal "system.registrations.payment_status_updated", audit_logger.calls.last[:action]
    end

    test "marks registration failed on failed payment" do
      audit_logger = FakeAuditLogger.new([])
      registration = FakeRegistration.new(TempleRegistration::PAYMENT_STATUSES[:pending], "REG-3", :temple)
      RegistrationPaymentSync.call(
        FakePayment.new(3, TemplePayment::STATUSES[:failed], "fake", "pay_3", registration),
        audit_logger: audit_logger
      )

      assert_equal TempleRegistration::PAYMENT_STATUSES[:failed], registration.payment_status
      assert_equal "system.registrations.payment_status_updated", audit_logger.calls.last[:action]
    end

    test "does not log when registration status does not change" do
      audit_logger = FakeAuditLogger.new([])
      registration = FakeRegistration.new(TempleRegistration::PAYMENT_STATUSES[:paid], "REG-4", :temple)

      RegistrationPaymentSync.call(
        FakePayment.new(4, TemplePayment::STATUSES[:completed], "fake", "pay_4", registration),
        audit_logger: audit_logger
      )

      assert_empty audit_logger.calls
    end
  end
end
