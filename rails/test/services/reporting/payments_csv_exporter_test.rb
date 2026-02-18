require "test_helper"

module Reporting
  class PaymentsCsvExporterTest < ActiveSupport::TestCase
    test "generates csv with payment rows" do
      temple = create_temple
      offering = TempleOffering.create!(
        temple:,
        slug: "offering",
        title: "Ancestor Rites",
        starts_on: Date.current,
        ends_on: Date.current + 1.day,
        offering_type: "general",
        currency: "TWD",
        price_cents: 600
      )
      user = User.create!(
        email: "guest@example.com",
        english_name: "Guest",
        encrypted_password: User.password_hash("Password123!")
      )
      registration = TempleEventRegistration.create!(
        temple:,
        registrable: offering,
        user:,
        quantity: 1,
        contact_payload: {},
        logistics_payload: {},
        metadata: { "registration_period_key" => "2026-ghost-month" }
      )
      payment = TemplePayment.create!(
        temple:,
        temple_event_registration: registration,
        user:,
        provider: "demo",
        provider_account: "temple",
        payment_method: TemplePayment::PAYMENT_METHODS[:cash],
        status: TemplePayment::STATUSES[:completed],
        amount_cents: 600,
        currency: "TWD",
        processed_at: Time.zone.parse("2026-01-03"),
        metadata: {},
        payment_payload: {}
      )

      exporter = PaymentsCsvExporter.new(payments: temple.temple_payments)
      csv = exporter.to_csv

      assert_includes csv, "Reference"
      assert_includes csv, payment.temple_event_registration.reference_code
      assert_includes csv, "Ancestor Rites"
      assert_includes csv, "Registration Period Key"
      assert_includes csv, "2026-ghost-month"
      assert_includes csv, "cash"
    end
  end
end
