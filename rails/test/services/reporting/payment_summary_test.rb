require "test_helper"

module Reporting
  class PaymentSummaryTest < ActiveSupport::TestCase
    test "aggregates totals by method offering and date" do
      temple = create_temple
      offering = TempleOffering.create!(
        temple:,
        slug: "lantern",
        title: "Lantern",
        currency: "TWD",
        price_cents: 400
      )
      user = User.create!(
        email: "member@example.com",
        english_name: "Member",
        encrypted_password: User.password_hash("Password123!")
      )
      registration = TempleEventRegistration.create!(
        temple:,
        temple_offering: offering,
        user:,
        quantity: 1,
        contact_payload: {},
        logistics_payload: {},
        metadata: {},
        payment_status: TempleEventRegistration::PAYMENT_STATUSES[:paid]
      )
      TemplePayment.create!(
        temple:,
        temple_event_registration: registration,
        user:,
        payment_method: TemplePayment::PAYMENT_METHODS[:cash],
        status: TemplePayment::STATUSES[:completed],
        amount_cents: 500,
        currency: "TWD",
        processed_at: Time.zone.parse("2026-01-01"),
        metadata: {},
        payment_payload: {}
      )
      TemplePayment.create!(
        temple:,
        temple_event_registration: registration,
        user:,
        payment_method: TemplePayment::PAYMENT_METHODS[:line_pay],
        status: TemplePayment::STATUSES[:completed],
        amount_cents: 400,
        currency: "TWD",
        processed_at: Time.zone.parse("2026-01-02"),
        metadata: {},
        payment_payload: {}
      )

      summary = PaymentSummary.new(payments: temple.temple_payments)

      assert_equal 900, summary.total_amount_cents
      assert_equal 2, summary.total_count
      assert_equal %w[cash line_pay], summary.totals_by_method.map { |entry| entry[:label] }
      assert_equal ["Lantern"], summary.totals_by_offering.map { |entry| entry[:label] }.uniq
      assert_equal %w[2026-01-01 2026-01-02], summary.totals_by_date.map { |entry| entry[:label] }
    end
  end
end
