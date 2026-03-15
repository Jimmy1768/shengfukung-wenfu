require "test_helper"

class AdminPermissionsManagementTest < ActionDispatch::IntegrationTest
  test "owner can update permissions for another admin" do
    temple = create_temple
    owner = create_admin_user(temple:)
    staff = create_admin_user(temple:)
    staff.admin_account.update!(role: "admin")

    staff_permission = AdminPermission.find_or_create_by!(admin_account: staff.admin_account, temple:)
    staff_permission.update!(AdminPermission::CAPABILITIES.index_with { false })

    sign_in_admin(owner)

    patch admin_permission_path(staff.admin_account), params: {
      admin_permission: {
        manage_offerings: "1",
        manage_registrations: "1",
        view_financials: "1"
      }
    }

    assert_redirected_to admin_permissions_path
    staff_permission.reload
    assert staff_permission.manage_offerings
    assert staff_permission.manage_registrations
    assert staff_permission.view_financials
  end

  test "admin without manage permissions is redirected" do
    temple = create_temple
    admin_user = create_admin_user(temple:)
    permission = AdminPermission.find_by(admin_account: admin_user.admin_account, temple:)
    permission.update!(manage_permissions: false)

    sign_in_admin(admin_user)

    get admin_permissions_path

    assert_redirected_to admin_dashboard_path
    assert_equal "You do not have access to manage permissions.", flash[:alert]
  end
end
