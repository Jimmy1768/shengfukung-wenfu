require "test_helper"

class AdminSessionsTest < ActionDispatch::IntegrationTest
  test "signs in with seeded admin credentials" do
    temple = create_temple(slug: "shengfukung-wenfu")
    admin = create_admin_user(temple:)

    post admin_sessions_path, params: { session: { email: admin.email, password: "Password123!" } }
    assert_redirected_to admin_dashboard_path
  end

  test "rejects invalid credentials" do
    temple = create_temple
    admin = create_admin_user(temple:)

    post admin_sessions_path, params: { session: { email: admin.email, password: "wrong" } }
    assert_response :unprocessable_entity
  end

  test "login page includes responsive viewport metadata" do
    get admin_login_path

    assert_response :success
    assert_includes response.body, '<meta name="viewport" content="width=device-width, initial-scale=1" />'
  end
end
