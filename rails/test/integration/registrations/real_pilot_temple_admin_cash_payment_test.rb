# frozen_string_literal: true

require "test_helper"

module Registrations
  # Director's actual scenario: sales creates a registration on a real
  # prospective client's behalf (in front of them, live) for the shengfukung-demo
  # demo temple's real offerings (NT$50 fake fee, no ECPay), then records it
  # as paid via cash -- purely to show the accounting/ledger system working,
  # no real money moves. Confirms this needs no bespoke per-temple helper --
  # it's the existing generic admin create + cash-payment flow, proven here
  # against a real offering instead of a synthetic fixture.
  class RealPilotTempleAdminCashPaymentTest < ActionDispatch::IntegrationTest
    test "admin creates a registration for a real demo-temple offering on a patron's behalf, then completes it with cash -- no ECPay, ledger reflects it" do
      temple = create_temple(
        slug: "shengfukung-demo",
        metadata: {
          "registration_periods" => [
            { "key" => "perennial", "label_zh" => "常年供燈", "label_en" => "Perennial" }
          ]
        }
      )
      template = Offerings::TemplateLoader.new(temple.slug).services.find { |entry| entry[:slug] == "incense-donation" }
      temple.temple_services.create!(
        slug: template[:slug], title: template[:label], status: "published",
        registration_period_key: template[:registration_period_key],
        price_cents: template.dig(:attributes, :price_cents), currency: template.dig(:attributes, :currency)
      )
      Offerings::TemplateSync.call(temple)
      offering = temple.temple_services.find_by!(slug: "incense-donation")
      assert_equal 5000, offering.price_cents
      assert_equal "TWD", offering.currency

      patron = User.create!(
        email: "cash-demo-patron@example.com",
        english_name: "Cash Demo Patron",
        encrypted_password: User.password_hash("Password123!")
      )
      admin = create_admin_user(temple:, permission_overrides: { manage_registrations: true, record_cash_payments: true })
      sign_in_admin(admin)

      # 1. Sales creates the registration on the patron's behalf, live.
      post admin_service_offering_orders_path(offering), params: {
        temple_event_registration: {
          user_id: patron.id, quantity: 1, registrant_scope: "self",
          contact_details: { primary_contact: patron.english_name, phone: "0900000000" }
        }
      }
      registration = offering.temple_event_registrations.order(:id).last
      assert registration.present?
      assert_equal "pending", registration.payment_status
      assert_equal 5000, registration.total_price_cents

      # 2. Sales presses Cash to complete it -- exact registration total,
      #    no ECPay/online provider involved.
      assert_difference -> { FinancialLedgerEntry.count }, 1 do
        post admin_payments_path(registration_id: registration.id),
          params: { temple_payment: { amount_cents: "5000", currency: "TWD" } }
      end
      assert_redirected_to admin_service_offering_order_path(offering, registration)

      registration.reload
      assert_equal "paid", registration.payment_status
      payment = registration.temple_payments.sole
      assert_equal "manual_cash", payment.provider
      assert_equal "cash", payment.payment_method

      # 3. Accounting reflects it.
      ledger_entry = FinancialLedgerEntry.order(:id).last
      assert_equal registration.id, ledger_entry.details["registration_id"]
      assert_equal "posted", ledger_entry.status
      assert_equal BigDecimal("50.0"), ledger_entry.amount
    end
  end
end
