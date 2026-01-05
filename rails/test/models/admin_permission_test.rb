require "test_helper"

class AdminPermissionTest < ActiveSupport::TestCase
  test "enforces uniqueness per admin and temple" do
    temple = create_temple
    admin_user = create_admin_user(temple:, create_permission: false)
    admin_account = admin_user.admin_account

    AdminPermission.create!(admin_account:, temple:)
    duplicate = AdminPermission.new(admin_account:, temple:)

    assert_not duplicate.valid?
  end

  test "reports capabilities via allow?" do
    temple = create_temple
    admin_user = create_admin_user(temple:)
    permission = AdminPermission.find_by(admin_account: admin_user.admin_account, temple:)

    permission.update!(manage_offerings: true)
    assert permission.allow?(:manage_offerings)
    refute permission.allow?(:export_financials)
  end
end
