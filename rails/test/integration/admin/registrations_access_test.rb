require "test_helper"

class AdminRegistrationsAccessTest < ActionDispatch::IntegrationTest
  setup do
    @temple = create_temple
    @offering = create_offering(temple: @temple, title: "Lamp Offering")
  end

  test "admin with manage_registrations can view registrations entry page" do
    admin = create_admin_user(temple: @temple)
    permission = AdminPermission.find_by(admin_account: admin.admin_account, temple: @temple)
    permission.update!(manage_registrations: true)

    sign_in_admin(admin)
    get admin_registrations_path

    assert_response :success
    assert_includes response.body, "Create New Registration"
    assert_includes response.body, "Lamp Offering"
    assert_includes response.body, new_admin_event_offering_order_path(@offering)
  end

  test "admin without manage_registrations is redirected from registrations entry page" do
    admin = create_admin_user(temple: @temple)
    permission = AdminPermission.find_by(admin_account: admin.admin_account, temple: @temple)
    permission.update!(manage_registrations: false)

    sign_in_admin(admin)
    get admin_registrations_path

    assert_redirected_to admin_dashboard_path
  end
end
