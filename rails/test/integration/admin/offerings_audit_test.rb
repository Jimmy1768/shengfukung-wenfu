require "test_helper"

class AdminOfferingsAuditTest < ActionDispatch::IntegrationTest
  setup do
    @temple = create_temple
    @admin = create_admin_user(temple: @temple)
    permission = AdminPermission.find_by(admin_account: @admin.admin_account, temple: @temple)
    permission.update!(manage_offerings: true)
  end

  test "creating an offering logs audit event" do
    sign_in_admin(@admin)

    assert_difference -> { SystemAuditLog.where(action: "admin.offerings.create").count }, 1 do
      post admin_offerings_path, params: {
        offering_kind: "service",
        temple_service: {
          slug: "spring-festival",
          title: "Spring Service",
          description: "Test",
          price_cents: 1000,
          currency: "TWD",
          status: "published",
          active: true
        }
      }
    end

    log = SystemAuditLog.order(created_at: :desc).find_by(action: "admin.offerings.create")
    assert_equal @admin.admin_account, log.admin_account
    assert_equal @temple, log.temple
  end

  test "creating a templated service persists metadata-backed form fields" do
    @temple.update!(
      slug: "shengfukung-demo",
      metadata: {
        "registration_periods" => [
          { "key" => "perennial", "label_zh" => "常年供燈", "label_en" => "Perennial" }
        ]
      }
    )

    sign_in_admin(@admin)

    assert_difference -> { @temple.reload.temple_services.count }, 1 do
      post admin_offerings_path, params: {
        offering_kind: "service",
        template_slug: "incense-oil",
        temple_service: {
          title: "香油錢",
          description: "敬獻香油以支持廟務運作，廟方依祈願安排上香儀程。",
          price_cents: 100,
          currency: "TWD",
          status: "draft",
          registration_period_key: "perennial",
          metadata_settings: {
            fulfillment_method: "信眾親領",
            logistics_notes: "請現場確認"
          }
        }
      }
    end

    service = @temple.reload.temple_services.order(created_at: :desc).first
    assert_redirected_to admin_service_path(service)
    assert_equal "信眾親領", service.metadata["fulfillment_method"]
    assert_equal "請現場確認", service.metadata["logistics_notes"]
    assert_equal 10_000, service.price_cents
  end

  test "updating an offering logs audit event" do
    offering = TempleService.create!(
      temple: @temple,
      slug: "lantern",
      title: "Lantern",
      currency: "TWD",
      price_cents: 500
    )

    sign_in_admin(@admin)

    assert_difference -> { SystemAuditLog.where(action: "admin.offerings.update").count }, 1 do
      patch admin_service_path(offering), params: {
        temple_service: {
          title: "Lantern Deluxe"
        }
      }
    end

    log = SystemAuditLog.order(created_at: :desc).find_by(action: "admin.offerings.update")
    assert_equal offering, log.target
    assert_includes log.metadata["changes"].keys, "title"
  end

  test "registration default audit records field names without entered values" do
    AdminPermission.find_by!(admin_account: @admin.admin_account, temple: @temple).update!(manage_registrations: true)
    offering = TempleOffering.create!(
      temple: @temple,
      slug: "audit-registration-defaults",
      title: "Audit registration defaults",
      starts_on: Date.current,
      ends_on: Date.current + 1.day,
      currency: "TWD",
      price_cents: 100,
      metadata: { "registration_form" => { "sections" => { "logistics" => ["arrival_window"], "ritual_metadata" => [] } } }
    )
    patron = User.create!(email: "audit-defaults@example.com", english_name: "Audit Patron", encrypted_password: User.password_hash("Password123!"))
    registration = create_registration(user: patron, offering:, metadata: { "registrant_scope" => "self" })
    secret = "private arrival instruction"

    sign_in_admin(@admin)

    assert_difference -> { SystemAuditLog.where(action: "temple.registration.update").count }, 1 do
      patch admin_event_offering_order_path(offering, registration), params: {
        temple_event_registration: { logistics_details: { arrival_window: secret } }
      }
    end

    log = SystemAuditLog.where(action: "temple.registration.update").order(:id).last
    assert_equal "admin_offering_orders", log.metadata.fetch("source")
    assert_equal ["arrival_window"], log.metadata.fetch("changed_reusable_fields")
    refute_includes log.metadata.to_json, secret
    refute_includes log.metadata.to_json, patron.email
  end
end
