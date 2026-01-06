require "test_helper"

class AdminPatronPickerTest < ActionDispatch::IntegrationTest
  setup do
    @temple = create_temple
    @admin = create_admin_user(temple: @temple)
    @permission = AdminPermission.find_by(admin_account: @admin.admin_account, temple: @temple)
    @permission.update!(manage_registrations: true)
  end

  test "search returns patrons by name" do
    user = User.create!(
      email: "patron@example.com",
      english_name: "Lantern Seeker",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_admin(@admin)

    get admin_patrons_path(format: :json), params: { q: "Lantern" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal user.id, body["patrons"].first["id"]
  end

  test "create makes a new patron profile" do
    sign_in_admin(@admin)

    assert_difference -> { User.count }, 1 do
      assert_difference -> { SystemAuditLog.where(action: "admin.patrons.create").count }, 1 do
        post admin_patrons_path(format: :json), params: {
          patron: {
            english_name: "New Patron",
            email: "newpatron@example.com",
            phone: "0900-000-000"
          }
        }, as: :json
      end
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "New Patron", body.dig("patron", "name")
  end

  test "unauthorized admin cannot access patron endpoints" do
    @permission.update!(manage_registrations: false)
    sign_in_admin(@admin)

    get admin_patrons_path(format: :json)

    assert_redirected_to admin_dashboard_path
  end
end
