require "test_helper"

module Reporting
  class PaymentSummaryTest < ActiveSupport::TestCase
  test "aggregates totals by method offering date and status" do
      temple = create_temple
      offering = TempleOffering.create!(
        temple:,
        slug: "lantern",
        title: "Lantern",
        starts_on: Date.current,
        ends_on: Date.current + 1.day,
        offering_type: "general",
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
        registrable: offering,
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
        provider: "demo",
        provider_account: "temple",
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
        provider: "demo",
        provider_account: "temple",
        payment_method: TemplePayment::PAYMENT_METHODS[:ecpay],
        status: TemplePayment::STATUSES[:completed],
        amount_cents: 400,
        currency: "TWD",
        processed_at: Time.zone.parse("2026-01-02"),
        metadata: {},
        payment_payload: {}
      )
      TemplePayment.create!(
        temple:,
        temple_event_registration: registration,
        user:,
        provider: "demo",
        provider_account: "temple",
        payment_method: TemplePayment::PAYMENT_METHODS[:cash],
        status: TemplePayment::STATUSES[:pending],
        amount_cents: 300,
        currency: "TWD",
        processed_at: Time.zone.parse("2026-01-03"),
        metadata: {},
        payment_payload: {}
      )
      TemplePayment.create!(
        temple:,
        temple_event_registration: registration,
        user:,
        provider: "demo",
        provider_account: "temple",
        payment_method: TemplePayment::PAYMENT_METHODS[:cash],
        status: TemplePayment::STATUSES[:refunded],
        amount_cents: 200,
        currency: "TWD",
        processed_at: Time.zone.parse("2026-01-04"),
        metadata: {},
        payment_payload: {}
      )

      summary = PaymentSummary.new(payments: temple.temple_payments)

      assert_equal 1400, summary.total_amount_cents
      assert_equal 4, summary.total_count
      assert_equal 900, summary.completed_amount_cents
      assert_equal 2, summary.completed_count
      assert_equal 1, summary.pending_count
      assert_equal 1, summary.refunded_count
      assert_equal %w[cash ecpay], summary.totals_by_method.map { |entry| entry[:label] }
      assert_equal ["Event · Lantern"], summary.totals_by_offering.map { |entry| entry[:label] }.uniq
      assert_equal %w[2026-01-01 2026-01-02 2026-01-03 2026-01-04], summary.totals_by_date.map { |entry| entry[:label] }
  end
  end
end
