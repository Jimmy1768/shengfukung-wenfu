# frozen_string_literal: true

require "test_helper"

module Registrations
  # Proves the exact sequence the Director's sales team will perform live,
  # laptop (admin console) + iPhone (patron), against a real offering
  # (incense-donation, already live on production via
  # offerings:apply_templates): patron self-registers -> admin completes
  # the registration with the details the patron-side form can't capture ->
  # admin accepts cash (fake) -> the payments/accounting screen reflects it.
  # This chains together three things each already proven in isolation
  # (patron self-registration, admin edit incl. the certificate_number fix,
  # admin cash completion) but never end to end in this exact order --
  # patron-creates-then-admin-edits is a different sequence than any prior
  # test (which had admin create from scratch, or patron register with no
  # follow-up admin edit).
  class RealPilotTempleSalesDemoScriptTest < ActionDispatch::IntegrationTest
    setup do
      @temple = create_temple(slug: "shengfukung-demo", metadata: {
        "registration_periods" => [{ "key" => "perennial", "label_zh" => "常年供燈", "label_en" => "Perennial" }]
      })
      template = Offerings::TemplateLoader.new(@temple.slug).services.find { |entry| entry[:slug] == "incense-donation" }
      @temple.temple_services.create!(
        slug: template[:slug], title: template[:label], status: "published",
        registration_period_key: template[:registration_period_key],
        price_cents: template.dig(:attributes, :price_cents), currency: template.dig(:attributes, :currency)
      )
      Offerings::TemplateSync.call(@temple)
      @offering = @temple.temple_services.find_by!(slug: "incense-donation")

      @patron = User.create!(email: "sales-demo-patron@example.com", english_name: "Sales Demo Patron",
        encrypted_password: User.password_hash("Password123!"))
      @admin = create_admin_user(temple: @temple, role: "owner",
        permission_overrides: { manage_registrations: true, record_cash_payments: true, view_financials: true })
    end

    test "patron self-registers, admin completes it, admin accepts cash, accounting reflects it" do
      # 1. Patron (iPhone) selects the offering and self-registers -- intent only.
      sign_in_account(@patron, temple_slug: @temple.slug)
      post account_registrations_path, params: {
        offering: @offering.slug, account_action: "service",
        account_registration_intake_form: { quantity: 1, contact_name: @patron.english_name, contact_phone: "0911222333" }
      }
      registration = @offering.temple_event_registrations.order(:id).last
      assert registration.present?, "patron self-registration should have created a registration"
      assert_equal "pending", registration.payment_status
      assert_nil registration.metadata["dedication_message"], "sanity check: patron-side form must not have set the offering-specific field"

      # 2. Admin (laptop) completes it -- adds the field the patron-facing
      #    form never asked for. This is the same admin edit path the
      #    certificate_number fix landed in.
      sign_in_admin(@admin)
      patch admin_service_offering_order_path(@offering, registration), params: {
        temple_event_registration: {
          user_id: @patron.id, quantity: 1, registrant_scope: "self",
          contact_details: { primary_contact: @patron.english_name, phone: "0911222333" },
          ritual_metadata: { dedication_message: "祝壽" }
        }
      }
      assert_response :redirect
      registration.reload
      assert_equal "祝壽", registration.metadata["dedication_message"]
      assert_equal "pending", registration.payment_status, "still awaiting payment after admin completes it"

      # 3. Admin presses Accept Cash (fake, no real money).
      assert_difference -> { FinancialLedgerEntry.count }, 1 do
        post admin_payments_path(registration_id: registration.id),
          params: { temple_payment: { amount_cents: registration.total_price_cents.to_s, currency: registration.currency } }
      end
      assert_redirected_to admin_service_offering_order_path(@offering, registration)
      registration.reload
      assert_equal "paid", registration.payment_status
      payment = registration.temple_payments.sole
      assert_equal "manual_cash", payment.provider
      assert_equal "cash", payment.payment_method

      # 4. The accounting screen (Payments index, view_financials-gated)
      #    reflects it -- this is the actual sales pitch moment.
      get admin_payments_path
      assert_response :success
      assert_includes response.body, @patron.english_name
      assert_includes response.body, Currency::Symbols.format_amount(payment.amount_cents, payment.currency)
      assert_includes response.body, I18n.t("admin.payments.methods.cash")

      ledger_entry = FinancialLedgerEntry.order(:id).last
      assert_equal registration.id, ledger_entry.details["registration_id"]
      assert_equal "posted", ledger_entry.status
    end
  end
end
