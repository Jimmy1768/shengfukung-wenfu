require "test_helper"

module Payments
  class CashPaymentRecorderTest < ActiveSupport::TestCase
    test "records ledger entry and payment" do
      temple = create_temple
      offering = TempleOffering.create!(temple:, slug: "lamp", title: "Lamp", currency: "TWD", price_cents: 500)
      registration = TempleEventRegistration.create!(
        temple:,
        temple_offering: offering,
        quantity: 1,
        contact_payload: {},
        logistics_payload: {},
        metadata: {}
      )
      admin = create_admin_user(temple:)

      recorder = CashPaymentRecorder.new(
        registration:,
        admin_user: admin,
        amount_cents: 500,
        currency: "TWD",
        notes: "Cash at desk"
      )

      payment = recorder.record!

      assert_equal TemplePayment::STATUSES[:completed], payment.status
      assert_equal TemplePayment::PAYMENT_METHODS[:cash], payment.payment_method
      assert payment.financial_ledger_entry.present?
      assert_equal TempleEventRegistration::PAYMENT_STATUSES[:paid], registration.reload.payment_status
    end
  end
end
