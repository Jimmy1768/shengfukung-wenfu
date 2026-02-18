require "test_helper"

class AdminServicesRegistrationPeriodGovernanceTest < ActionDispatch::IntegrationTest
  setup do
    @temple = create_temple(
      slug: "demo-lotus",
      metadata: {
        "registration_periods" => [
          { "key" => "perennial", "label_zh" => "全年", "label_en" => "Year-round" },
          { "key" => "2026-ghost-month", "label_zh" => "2026 普渡月", "label_en" => "2026 Ghost Month" }
        ]
      }
    )
    @admin = create_admin_user(temple: @temple)
    permission = AdminPermission.find_by(admin_account: @admin.admin_account, temple: @temple)
    permission.update!(manage_offerings: true)
  end

  test "rejects unknown registration period key on create" do
    sign_in_admin(@admin)

    assert_no_difference -> { @temple.temple_services.count } do
      post admin_services_path, params: {
        template_slug: "lotus-light",
        temple_service: {
          slug: "ancestor-lamp",
          title: "Ancestor Lamp",
          description: "Test offering",
          price_cents: 500,
          currency: "TWD",
          status: "draft",
          registration_period_key: "custom-adhoc-period"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "must match a configured temple registration period key"
  end

  test "accepts configured registration period key on create" do
    sign_in_admin(@admin)

    assert_difference -> { @temple.temple_services.count }, 1 do
      post admin_services_path, params: {
        template_slug: "lotus-light",
        temple_service: {
          slug: "peace-light",
          title: "Peace Light",
          description: "Test offering",
          price_cents: 800,
          currency: "TWD",
          status: "draft",
          registration_period_key: "2026-ghost-month"
        }
      }
    end

    service = @temple.temple_services.order(created_at: :desc).first
    assert_redirected_to admin_service_path(service)
    assert_equal "2026-ghost-month", service.registration_period_key
    assert_equal "2026 Ghost Month", service.period_label
  end

  test "rejects unknown registration period key on update" do
    service = @temple.temple_services.create!(
      slug: "blessing",
      title: "Blessing",
      currency: "TWD",
      price_cents: 600,
      status: "draft",
      registration_period_key: "perennial",
      period_label: "Year-round"
    )
    sign_in_admin(@admin)

    patch admin_service_path(service), params: {
      temple_service: {
        registration_period_key: "other-manual-period"
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "must match a configured temple registration period key"
    assert_equal "perennial", service.reload.registration_period_key
  end
end
