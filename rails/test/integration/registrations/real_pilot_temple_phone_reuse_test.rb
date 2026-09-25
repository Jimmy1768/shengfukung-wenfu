# frozen_string_literal: true

require "test_helper"

module Registrations
  # Uses the real pilot-temple offering catalog (Offerings::TemplateSync
  # against the actual shengfukung-demo.yml), not a synthetic offering --
  # existing coverage (prefill_and_override_test.rb, offering_orders_registrant_flow_test.rb)
  # proves the mechanism against schema-equivalent fixtures; this proves it
  # against one of the 4 real, currently-configured offerings specifically,
  # for the one field (phone) declared identically across all 4.
  class RealPilotTemplePhoneReuseTest < ActionDispatch::IntegrationTest
    test "phone flows patron -> admin correction -> next registration prefill, cross surface, without ever touching the patron's own profile" do
      temple = create_temple(
        slug: "shengfukung-demo",
        metadata: {
          "registration_periods" => [
            { "key" => "perennial", "label_zh" => "常年供燈", "label_en" => "Perennial" }
          ]
        }
      )
      # TemplateSync only updates offerings that already exist by slug (the
      # real onboarding flow creates them via the admin draft/review/apply
      # workflow) -- bootstrap the base record here, then let the real sync
      # service layer on the actual registration_form metadata from the
      # real YAML, same as it would in production.
      template = Offerings::TemplateLoader.new(temple.slug).services.find { |entry| entry[:slug] == "incense-donation" }
      temple.temple_services.create!(
        slug: template[:slug], title: template[:label], status: "published",
        registration_period_key: template[:registration_period_key],
        price_cents: template.dig(:attributes, :price_cents), currency: template.dig(:attributes, :currency)
      )
      Offerings::TemplateSync.call(temple)
      offering = temple.temple_services.find_by!(slug: "incense-donation")
      assert_includes offering.metadata.dig("registration_form", "sections", "contact", "fields"), "phone",
        "sanity check: the real YAML must still declare phone as a contact field for this offering"

      patron = User.create!(
        email: "phone-reuse-patron@example.com",
        english_name: "Phone Reuse Patron",
        encrypted_password: User.password_hash("Password123!")
      )
      admin = create_admin_user(temple:, permission_overrides: { manage_registrations: true })

      # 1. Patron self-registers for the real offering with their own phone.
      sign_in_account(patron, temple_slug: temple.slug)
      post account_registrations_path, params: {
        offering: offering.slug, account_action: "service",
        account_registration_intake_form: { quantity: 1, contact_phone: "0911111111" }
      }
      registration = offering.temple_event_registrations.order(:id).last
      assert registration.present?, "registration should have been created"

      # phone is cached as account-level registration contact, NOT offering-scoped
      # like arrival_window/ritual_metadata (those live in ReusableDefaults).
      # Since 2026-08-28 it is namespaced away from the patron's own profile
      # fields so staff can never silently rewrite them -- see
      # Registrations::UserMetadataUpdater.
      patron.reload
      assert_equal "0911111111", patron.metadata.dig(Registrations::UserMetadataUpdater::NAMESPACE, "phone")
      assert_nil patron.metadata["phone"], "a registration must not write the patron's own profile phone"

      # 2. Admin, assisting the same patron (in person / by phone), corrects
      #    that same registration's phone number.
      sign_in_admin(admin)
      patch admin_service_offering_order_path(offering, registration), params: {
        temple_event_registration: {
          user_id: patron.id, quantity: 1, registrant_scope: "self",
          contact_details: { phone: "0922222222" }
        }
      }
      assert_response :redirect
      patron.reload
      assert_equal "0922222222", patron.metadata.dig(Registrations::UserMetadataUpdater::NAMESPACE, "phone"),
        "admin's correction should win within the registration-contact cache -- last write wins, no conflicting-source error"
      assert_nil patron.metadata["phone"],
        "the whole point of W1: an admin correction must never reach the patron's own profile"

      # 3. The *next* registration -- account surface this time, patron
      #    signing back in as themselves -- prefills the admin's corrected
      #    value, not the patron's original one -- read precedence is what
      #    keeps rule 3 ("don't make an admin ask again") working now that
      #    prefill no longer reads the profile.
      sign_in_account(patron, temple_slug: temple.slug)
      get new_account_registration_path(offering: offering.slug, account_action: "service")
      assert_response :success
      assert_select "input[name='account_registration_intake_form[contact_phone]'][value=?]", "0922222222"
    end
  end
end
