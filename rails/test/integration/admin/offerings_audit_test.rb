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
end
