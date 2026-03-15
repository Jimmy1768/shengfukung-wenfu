require "test_helper"

class AdminAccountClosureTest < ActionDispatch::IntegrationTest
  test "closed admin account cannot sign in" do
    temple = create_temple(slug: "admin-closure-temple")
    user = User.create!(
      email: "closed-admin@example.com",
      english_name: "Closed Admin",
      encrypted_password: User.password_hash("Password123!")
    )
    admin_account = AdminAccount.create!(user: user, role: "owner", active: true)
    AdminTempleMembership.create!(admin_account: admin_account, temple: temple, role: "owner")
    AdminPermission.create!(admin_account: admin_account, temple: temple, manage_permissions: true)
    user.close_account!(reason: "self_service")

    post admin_login_path, params: {
      session: {
        email: user.email,
        password: "Password123!"
      }
    }

    assert_response :unprocessable_content
    assert_includes response.body, I18n.t("admin.sessions.flash.account_closed")
  end
end
