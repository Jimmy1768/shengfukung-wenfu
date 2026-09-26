# frozen_string_literal: true

require "test_helper"

module Registrations
  # Director's ask: confirm all 4 of the pilot temple's real offering
  # templates (db/temples/offerings/shengfukung-demo.yml) actually work
  # from the admin side -- bootstrap each as a real offering the way the
  # real onboarding flow would, then create a registration for it through
  # the real admin create-order flow. Prior coverage
  # (real_pilot_temple_phone_reuse_test.rb, real_pilot_temple_admin_cash_payment_test.rb)
  # only ever exercised "incense-oil" -- the other 3
  # (lamp-service, ghost-festival-table, liberation-ritual) had never been
  # proven this way. This is that proof, for all 4.
  class RealPilotTempleAllOfferingsAdminTest < ActionDispatch::IntegrationTest
    REGISTRATION_PERIODS = [
      { "key" => "perennial", "label_zh" => "常年供燈", "label_en" => "Perennial" },
      { "key" => "2026-lantern", "label_zh" => "2026 點燈", "label_en" => "2026 Lantern" },
      { "key" => "2026-ghost-month", "label_zh" => "2026 中元", "label_en" => "2026 Ghost Month" }
    ].freeze

    setup do
      @temple = create_temple(slug: "shengfukung-demo", metadata: { "registration_periods" => REGISTRATION_PERIODS })
      @admin = create_admin_user(temple: @temple, permission_overrides: { manage_registrations: true })
      @patron = User.create!(
        email: "all-offerings-patron@example.com",
        english_name: "All Offerings Patron",
        encrypted_password: User.password_hash("Password123!")
      )
    end

    test "incense-oil: admin creates a registration from the real template" do
      offering = bootstrap_offering!("incense-oil")
      assert_includes offering.metadata.dig("registration_form", "sections", "ritual_metadata", "fields"), "dedication_message"

      sign_in_admin(@admin)
      post admin_service_offering_orders_path(offering), params: {
        temple_event_registration: {
          user_id: @patron.id, quantity: 1, registrant_scope: "self",
          contact_details: { primary_contact: @patron.english_name, phone: "0900000001" },
          ritual_metadata: { dedication_message: "祝壽" }
        }
      }

      registration = assert_registration_created(offering)
      assert_equal 5000, registration.total_price_cents
      assert_equal "祝壽", registration.metadata["dedication_message"]
    end

    test "lamp-service: admin creates a registration from the real template" do
      offering = bootstrap_offering!("lamp-service")
      assert_includes offering.metadata.dig("registration_form", "sections", "logistics", "fields"), "preferred_slot"

      sign_in_admin(@admin)
      post admin_service_offering_orders_path(offering), params: {
        temple_event_registration: {
          user_id: @patron.id, quantity: 1, registrant_scope: "self", certificate_number: "L-0001",
          contact_details: { primary_contact: @patron.english_name, phone: "0900000002" },
          logistics_details: { preferred_date: Date.current.to_s, preferred_slot: "白天" },
          ritual_metadata: { ancestor_placard_name: "陳氏歷代祖先", dedication_message: "祝壽", certificate_notes: "請提前通知" }
        }
      }

      registration = assert_registration_created(offering)
      assert_equal 5000, registration.total_price_cents
      assert_equal "L-0001", registration.certificate_number
      assert_equal "白天", registration.logistics_payload["preferred_slot"]
      assert_equal "陳氏歷代祖先", registration.metadata["ancestor_placard_name"]

      # Regression: certificate_number is a metadata-backed virtual attribute;
      # editing it through the admin update flow must not silently revert to
      # the old value (same clobbering hazard as create, different call site).
      patch admin_service_offering_order_path(offering, registration), params: {
        temple_event_registration: {
          user_id: @patron.id, quantity: 1, registrant_scope: "self", certificate_number: "L-0002",
          contact_details: { primary_contact: @patron.english_name, phone: "0900000002" }
        }
      }
      assert_response :redirect
      assert_equal "L-0002", registration.reload.certificate_number
    end

    test "ghost-festival-table: admin creates a registration from the real template" do
      offering = bootstrap_offering!("ghost-festival-table")
      assert_includes offering.metadata.dig("registration_form", "sections", "logistics", "fields"), "ceremony_location"

      sign_in_admin(@admin)
      post admin_service_offering_orders_path(offering), params: {
        temple_event_registration: {
          user_id: @patron.id, quantity: 1, registrant_scope: "self",
          contact_details: { primary_contact: @patron.english_name, phone: "0900000003" },
          logistics_details: { preferred_date: Date.current.to_s, ceremony_location: "戶外祭壇" },
          ritual_metadata: { dedication_message: "祝壽" }
        }
      }

      registration = assert_registration_created(offering)
      assert_equal 5000, registration.total_price_cents
      assert_equal "戶外祭壇", registration.logistics_payload["ceremony_location"]
    end

    test "liberation-ritual: admin creates a registration from the real template" do
      offering = bootstrap_offering!("liberation-ritual")
      assert_includes offering.metadata.dig("registration_form", "sections", "ritual_metadata", "fields"), "ancestor_placard_name"

      sign_in_admin(@admin)
      post admin_service_offering_orders_path(offering), params: {
        temple_event_registration: {
          user_id: @patron.id, quantity: 1, registrant_scope: "self", certificate_number: "R-0001",
          contact_details: { primary_contact: @patron.english_name, phone: "0900000004" },
          logistics_details: { preferred_date: Date.current.to_s, ceremony_location: "本殿" },
          ritual_metadata: { ancestor_placard_name: "林氏歷代祖先", dedication_message: "拔薦歷代祖先", certificate_notes: "誦經三日" }
        }
      }

      registration = assert_registration_created(offering)
      assert_equal 5000, registration.total_price_cents
      assert_equal "R-0001", registration.certificate_number
      assert_equal "本殿", registration.logistics_payload["ceremony_location"]
    end

    private

    def bootstrap_offering!(slug)
      template = Offerings::TemplateLoader.new(@temple.slug).services.find { |entry| entry[:slug] == slug }
      raise "template #{slug.inspect} not found in db/temples/offerings/#{@temple.slug}.yml" unless template

      @temple.temple_services.create!(
        slug: template[:slug], title: template[:label], status: "published",
        registration_period_key: template[:registration_period_key],
        price_cents: template.dig(:attributes, :price_cents), currency: template.dig(:attributes, :currency)
      )
      Offerings::TemplateSync.call(@temple)
      @temple.temple_services.find_by!(slug:)
    end

    def assert_registration_created(offering)
      assert_response :redirect
      registration = offering.temple_event_registrations.order(:id).last
      assert registration.present?, "expected a registration to have been created for #{offering.slug}"
      assert_equal "pending", registration.payment_status
      registration
    end
  end
end
