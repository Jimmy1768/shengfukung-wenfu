require "test_helper"

class InternalTempleAccessTest < ActionDispatch::IntegrationTest
  test "configured operator can view temple access states" do
    operator_temple = create_temple(slug: "shengfukung-wenfu", name: "Shengfukung")
    other_temple = create_temple(slug: "demo-lotus", name: "Demo Lotus")

    operator = User.create!(
      email: "operator@example.com",
      encrypted_password: User.password_hash("Password123!"),
      english_name: "Operator"
    )
    admin_account = AdminAccount.create!(user: operator, active: true, role: "owner")
    AdminTempleMembership.create!(admin_account: admin_account, temple: operator_temple, role: "owner")
    AdminPermission.create!(admin_account: admin_account, temple: operator_temple, manage_permissions: true)

    with_env("INTERNAL_PLATFORM_OPERATOR_EMAIL" => "operator@example.com") do
      sign_in_admin(operator)

      get internal_temple_access_path

      assert_response :success
      assert_includes response.body, "Temple access"
      assert_includes response.body, operator_temple.slug
      assert_includes response.body, other_temple.slug
      assert_includes response.body, "Has access"
      assert_includes response.body, "No access"
    end
  end

  test "operator can grant owner access to a temple" do
    temple = create_temple(slug: "demo-lotus", name: "Demo Lotus")
    operator = create_operator!

    with_env("INTERNAL_PLATFORM_OPERATOR_EMAIL" => "operator@example.com") do
      sign_in_admin(operator)

      post internal_grant_temple_access_path(temple_id: temple.id, role: "owner")

      assert_redirected_to internal_temple_access_path
      membership = operator.admin_account.admin_temple_memberships.find_by!(temple:)
      assert_equal "owner", membership.role

      permission = AdminPermission.find_by!(admin_account: operator.admin_account, temple:)
      assert_equal true, permission.manage_permissions
    end
  end

  test "operator can grant admin access without permission management" do
    temple = create_temple(slug: "demo-lotus", name: "Demo Lotus")
    operator = create_operator!

    with_env("INTERNAL_PLATFORM_OPERATOR_EMAIL" => "operator@example.com") do
      sign_in_admin(operator)

      post internal_grant_temple_access_path(temple_id: temple.id, role: "admin")

      assert_redirected_to internal_temple_access_path
      membership = operator.admin_account.admin_temple_memberships.find_by!(temple:)
      assert_equal "staff", membership.role

      permission = AdminPermission.find_by!(admin_account: operator.admin_account, temple:)
      assert_equal false, permission.manage_permissions
      assert_equal true, permission.manage_offerings
    end
  end

  test "operator can revoke access from a temple" do
    temple = create_temple(slug: "demo-lotus", name: "Demo Lotus")
    operator = create_operator!
    AdminTempleMembership.create!(admin_account: operator.admin_account, temple:, role: "owner")
    AdminPermission.create!(admin_account: operator.admin_account, temple:, manage_permissions: true)

    with_env("INTERNAL_PLATFORM_OPERATOR_EMAIL" => "operator@example.com") do
      sign_in_admin(operator)

      delete internal_revoke_temple_access_path(temple_id: temple.id)

      assert_redirected_to internal_temple_access_path
      assert_nil operator.admin_account.admin_temple_memberships.find_by(temple:)
      assert_nil AdminPermission.find_by(admin_account: operator.admin_account, temple:)
    end
  end

  test "non-operator admin is redirected away" do
    temple = create_temple(slug: "shengfukung-wenfu")
    user = create_admin_user(temple: temple, password: "Password123!", role: "owner")

    with_env("INTERNAL_PLATFORM_OPERATOR_EMAIL" => "operator@example.com") do
      sign_in_admin(user)

      get internal_temple_access_path

      assert_redirected_to admin_dashboard_path
    end
  end

  private

  def create_operator!(temple: create_temple(slug: "operator-temple", name: "Operator Temple"))
    operator = User.create!(
      email: "operator@example.com",
      encrypted_password: User.password_hash("Password123!"),
      english_name: "Operator"
    )
    admin_account = AdminAccount.create!(user: operator, active: true, role: "owner")
    AdminTempleMembership.create!(admin_account:, temple:, role: "owner")
    AdminPermission.create!(admin_account:, temple:, manage_permissions: true)
    operator
  end

  def with_env(overrides)
    original = overrides.transform_values { |_,| nil }
    overrides.each_key { |key| original[key] = ENV[key] }
    overrides.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    yield
  ensure
    original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end
