# frozen_string_literal: true

require "test_helper"

module Registrations
  # Director's follow-up: can a patron actually select each of the 4 real
  # offering templates (db/temples/offerings/shengfukung-demo.yml) and
  # create a registration from the account side -- not just the admin side?
  # Prior coverage (real_pilot_temple_phone_reuse_test.rb) only ever
  # exercised patron self-registration against "incense-oil". Unlike
  # the admin create-order flow, Account::RegistrationIntakeForm and its
  # view are entirely generic -- they don't branch on the offering's
  # registration_form metadata at all, so the same fixed field set
  # (quantity, contact info, arrival_window, ceremony_notes) is offered
  # for every offering regardless of its template. That's a real,
  # deliberate product gap worth having on record (a patron self-registering
  # for lamp-service can't specify lamp type/location, dedication message,
  # etc. -- those stay admin-assisted-only) -- but it also means, unlike
  # the admin side, there's no reason to expect the 4 templates to behave
  # differently from each other here. Proven directly anyway, for all 4,
  # rather than assumed from reading the code.
  class RealPilotTempleAllOfferingsPatronTest < ActionDispatch::IntegrationTest
    REGISTRATION_PERIODS = [
      { "key" => "perennial", "label_zh" => "常年供燈", "label_en" => "Perennial" },
      { "key" => "2026-lantern", "label_zh" => "2026 點燈", "label_en" => "2026 Lantern" },
      { "key" => "2026-ghost-month", "label_zh" => "2026 中元", "label_en" => "2026 Ghost Month" }
    ].freeze

    setup do
      @temple = create_temple(slug: "shengfukung-demo", metadata: { "registration_periods" => REGISTRATION_PERIODS })
    end

    test "incense-oil: patron can select it and self-register" do
      assert_patron_can_register!("incense-oil")
    end

    test "lamp-service: patron can select it and self-register" do
      assert_patron_can_register!("lamp-service")
    end

    test "ghost-festival-table: patron can select it and self-register" do
      assert_patron_can_register!("ghost-festival-table")
    end

    test "liberation-ritual: patron can select it and self-register" do
      assert_patron_can_register!("liberation-ritual")
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

    def assert_patron_can_register!(slug)
      offering = bootstrap_offering!(slug)

      # 1. The offering must actually be selectable -- listed on the
      #    patron-facing services index, published and visible.
      patron = User.create!(
        email: "#{slug}-patron@example.com", english_name: "#{slug.tr('-', ' ').titleize} Patron",
        encrypted_password: User.password_hash("Password123!")
      )
      sign_in_account(patron, temple_slug: @temple.slug)

      get account_services_path
      assert_response :success
      assert_includes response.body, offering.title, "#{slug} should be listed as a selectable service"

      # 2. The new-registration form for this offering must actually load.
      get new_account_registration_path(offering: offering.slug, account_action: "service")
      assert_response :success

      # 3. The patron can actually submit and create a registration.
      post account_registrations_path, params: {
        offering: offering.slug, account_action: "service",
        account_registration_intake_form: {
          quantity: 1, contact_name: patron.english_name, contact_phone: "0911000000"
        }
      }

      registration = offering.temple_event_registrations.order(:id).last
      assert registration.present?, "#{slug}: expected a patron self-registration to have been created"
      assert_response :redirect
      assert_equal 5000, registration.total_price_cents
      assert_equal "pending", registration.payment_status
    end
  end
end
