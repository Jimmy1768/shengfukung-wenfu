# frozen_string_literal: true

require "test_helper"

class Admin::MultiTempleAccessTest < ActionDispatch::IntegrationTest
  test "staff remains scoped to their assigned temple" do
    alpha = create_temple(name: "Alpha Temple", slug: "alpha-temple")
    beta = create_temple(name: "Beta Temple", slug: "beta-temple")
    staff_user = create_admin_user(
      temple: alpha,
      role: "staff",
      membership_role: "staff",
      permission_overrides: { manage_offerings: true }
    )

    sign_in_admin(staff_user)
    assert_response :success
    assert_includes response.body, "Alpha Temple"
    refute_includes response.body, "Beta Temple"

    post admin_temple_switch_path, params: { temple_switch: { temple_slug: beta.slug } }
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Alpha Temple"
    assert_match "owner accounts", response.body

    get admin_dashboard_path, params: { temple_slug: beta.slug }
    assert_response :success
    assert_includes response.body, "Alpha Temple"
    refute_includes response.body, "Beta Temple"
  end

  test "owner can switch to another assigned temple" do
    alpha = create_temple(name: "Alpha Temple", slug: "alpha-temple")
    beta = create_temple(name: "Beta Temple", slug: "beta-temple")
    owner = create_admin_user(temple: alpha)
    AdminTempleMembership.create!(
      admin_account: owner.admin_account,
      temple: beta,
      role: "owner"
    )
    AdminPermission.create!(
      admin_account: owner.admin_account,
      temple: beta,
      manage_offerings: true,
      manage_permissions: true
    )

    sign_in_admin(owner)
    assert_response :success
    assert_select ".temple-switcher-select option[selected=selected]", text: "Alpha Temple"

    post admin_temple_switch_path, params: { temple_switch: { temple_slug: beta.slug } }
    follow_redirect!
    assert_response :success
    assert_match "Now viewing Beta Temple.", response.body
    assert_select ".temple-switcher-select option[selected=selected]", text: "Beta Temple"

    get admin_dashboard_path
    assert_response :success
    assert_select ".temple-switcher-select option[selected=selected]", text: "Beta Temple"
  end
end
