require "test_helper"

module Payments
  class CashPaymentRecorderTest < ActiveSupport::TestCase
    test "records ledger entry and payment" do
      temple = create_temple
      offering = TempleOffering.create!(
        temple:,
        slug: "lamp",
        title: "Lamp",
        currency: "TWD",
        price_cents: 500,
        starts_on: Date.current,
        ends_on: Date.current + 1.day
      )
      registration = TempleEventRegistration.create!(
        temple:,
        registrable: offering,
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

      payment = nil
      assert_difference -> { FinancialLedgerEntry.count }, 1 do
        payment = recorder.record!
      end

      assert_equal TemplePayment::STATUSES[:completed], payment.status
      assert_equal TemplePayment::PAYMENT_METHODS[:cash], payment.payment_method
      assert_equal "Cash at desk", payment.payment_payload["notes"]
      ledger_entry = FinancialLedgerEntry.find_by!(external_reference: registration.reference_code)
      assert_equal registration.id, ledger_entry.details["registration_id"]
      assert_equal 5, ledger_entry.amount.to_i
      assert_equal admin.admin_account.id, ledger_entry.metadata["recorded_by_admin_id"]
      assert_equal TempleEventRegistration::PAYMENT_STATUSES[:paid], registration.reload.payment_status
    end
  end
end
