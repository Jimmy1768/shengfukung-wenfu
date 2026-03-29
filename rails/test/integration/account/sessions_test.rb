require "test_helper"

module Account
  class SessionsTest < ActionDispatch::IntegrationTest
    test "login route escapes temple picker loop when active temple slug no longer resolves" do
      user = User.create!(
        email: "session-recovery@example.com",
        english_name: "Session Recovery",
        encrypted_password: User.password_hash("Password123!")
      )

      sign_in_account(user, temple_slug: "missing-temple")

      get account_login_path(temple: "shengfukung-wenfu")

      assert_redirected_to account_dashboard_path
    end

    test "signup route creates account with temple param even when no active temple is in session" do
      create_temple(slug: "shengfukung-wenfu")

      assert_difference -> { User.count }, 1 do
        post account_register_path, params: {
          temple: "shengfukung-wenfu",
          registration: {
            email: "new-signup@example.com",
            password: "Password123!",
            password_confirmation: "Password123!"
          }
        }
      end

      assert_redirected_to account_dashboard_path
    end

    test "login preserves temple context from login page form submission" do
      temple = create_temple(slug: "shengfukung-wenfu")
      user = User.create!(
        email: "login-preserve@example.com",
        english_name: "Login Preserve",
        encrypted_password: User.password_hash("Password123!")
      )

      get account_login_path(temple: temple.slug)
      assert_response :success

      post account_sessions_path, params: {
        temple: temple.slug,
        session: {
          email: user.email,
          password: "Password123!"
        }
      }

      assert_redirected_to account_dashboard_path
      follow_redirect!
      assert_response :success
    end

    test "signup preserves temple context from signup form submission" do
      temple = create_temple(slug: "shengfukung-wenfu")

      get account_login_path(temple: temple.slug)
      assert_response :success

      post account_register_path, params: {
        temple: temple.slug,
        registration: {
          email: "signup-preserve@example.com",
          password: "Password123!",
          password_confirmation: "Password123!"
        }
      }

      assert_redirected_to account_dashboard_path
      follow_redirect!
      assert_response :success
    end
  end
end
