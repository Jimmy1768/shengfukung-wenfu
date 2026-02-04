require "test_helper"

class AdminMethodOverrideTest < ActionDispatch::IntegrationTest
  test "HTML forms posting with _method patch update permissions" do
    temple = create_temple
    owner = create_admin_user(temple:)
    staff = create_admin_user(temple:)
    staff.admin_account.update!(role: "staff")

    staff_permission = AdminPermission.find_or_create_by!(admin_account: staff.admin_account, temple:)
    staff_permission.update!(AdminPermission::CAPABILITIES.index_with { false })

    sign_in_admin(owner)

    post admin_permission_path(staff.admin_account), params: {
      _method: "patch",
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
end
