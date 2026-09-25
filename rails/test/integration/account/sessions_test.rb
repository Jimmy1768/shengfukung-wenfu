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

      get account_login_path(temple_slug: "shengfukung-demo")

      assert_redirected_to account_dashboard_path
    end

    # LOAD-BEARING FOR OAUTH. Auth::CentralOAuthController no longer carries its
    # own copy of the post-login resolution -- it preserves the entry intent
    # across reset_session and redirects here, letting this single resolver turn
    # the intent into a destination. Break this and signing in with Google
    # silently goes back to dumping patrons on the dashboard.
    test "a signed-in visitor carrying an entry intent lands on the offering they clicked" do
      temple = create_temple(slug: "shengfukung-demo")
      gathering = temple.temple_gatherings.create!(
        slug: "fire-safety-drill",
        title: "消防救生活動",
        currency: "TWD",
        price_cents: 0,
        starts_on: Date.current + 20
      )
      user = User.create!(
        email: "intent-carrier@example.com",
        english_name: "Intent Carrier",
        encrypted_password: User.password_hash("Password123!")
      )
      sign_in_account(user, temple_slug: temple.slug)

      get account_login_path(
        account_action: "gathering",
        offering: gathering.slug,
        temple_slug: temple.slug
      )

      assert_redirected_to new_account_registration_path(
        temple_slug: temple.slug,
        account_action: "gathering",
        offering: gathering.slug
      )
    end

    test "a signed-in visitor with no entry intent still goes to the dashboard" do
      temple = create_temple(slug: "shengfukung-demo")
      user = User.create!(
        email: "no-intent@example.com",
        english_name: "No Intent",
        encrypted_password: User.password_hash("Password123!")
      )
      sign_in_account(user, temple_slug: temple.slug)

      get account_login_path(temple_slug: temple.slug)

      assert_redirected_to account_dashboard_path
    end

    test "signup route creates account with temple slug param even when no active temple is in session" do
      create_temple(slug: "shengfukung-demo")

      assert_difference -> { User.count }, 1 do
        post account_register_path, params: {
          temple_slug: "shengfukung-demo",
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
      temple = create_temple(slug: "shengfukung-demo")
      user = User.create!(
        email: "login-preserve@example.com",
        english_name: "Login Preserve",
        encrypted_password: User.password_hash("Password123!")
      )

      get account_login_path(temple_slug: temple.slug)
      assert_response :success

      post account_sessions_path, params: {
        temple_slug: temple.slug,
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
      temple = create_temple(slug: "shengfukung-demo")

      get account_login_path(temple_slug: temple.slug)
      assert_response :success

      post account_register_path, params: {
        temple_slug: temple.slug,
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

    test "legacy temple param is accepted only as an account context shim" do
      temple = create_temple(slug: "shengfukung-demo")

      get account_login_path(temple: temple.slug)

      assert_response :success
      assert_includes response.body, "temple_slug"
    end

    test "login page includes responsive viewport metadata" do
      temple = create_temple(slug: "shengfukung-demo")

      get account_login_path(temple_slug: temple.slug)

      assert_response :success
      assert_includes response.body, '<meta name="viewport" content="width=device-width, initial-scale=1" />'
    end
  end
end
