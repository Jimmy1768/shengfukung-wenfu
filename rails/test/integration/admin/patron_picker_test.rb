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
    staff = create_admin_user(
      temple: @temple,
      role: "admin",
      membership_role: "admin",
      permission_overrides: { manage_registrations: false, manage_permissions: false }
    )
    sign_in_admin(staff)

    get admin_patrons_path(format: :json)

    assert_redirected_to admin_dashboard_path
  end

  test "promote creates an admin membership for the current temple without inheriting owner role" do
    beta = create_temple(name: "Beta Temple", slug: "beta-temple")
    promoter = create_admin_user(temple: beta, role: "owner")
    target = create_admin_user(temple: @temple, role: "owner")

    sign_in_admin(promoter)

    assert_difference -> { target.admin_account.admin_temple_memberships.where(temple: beta).count }, 1 do
      post promote_admin_patron_path(target)
    end

    assert_redirected_to admin_patrons_path
    target.admin_account.reload
    assert_equal "admin", target.admin_account.membership_for(beta)&.role
  end

  test "revoke removes an admin membership from the current temple even when the account owns another temple" do
    beta = create_temple(name: "Beta Temple", slug: "beta-temple")
    revoker = create_admin_user(temple: beta, role: "owner")
    target = create_admin_user(temple: @temple, role: "owner")

    AdminTempleMembership.create!(
      admin_account: target.admin_account,
      temple: beta,
      role: "admin"
    )
    AdminPermission.create!(
      admin_account: target.admin_account,
      temple: beta,
      manage_offerings: true
    )

    sign_in_admin(revoker)

    assert_difference -> { target.admin_account.admin_temple_memberships.where(temple: beta).count }, -1 do
      assert_difference -> { target.admin_account.admin_permissions.where(temple: beta).count }, -1 do
        delete revoke_admin_patron_path(target)
      end
    end

    assert_redirected_to admin_patrons_path
    assert_nil target.admin_account.reload.membership_for(beta)
  end
end
