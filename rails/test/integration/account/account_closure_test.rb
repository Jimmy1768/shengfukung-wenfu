require "test_helper"

module Account
  class AccountClosureTest < ActionDispatch::IntegrationTest
    FakeCentralOAuthClient = Struct.new(:start_response, :exchange_response) do
      def start(**)
        start_response
      end

      def exchange(**)
        exchange_response
      end
    end

    test "closed account cannot sign in with email and password" do
      temple = create_temple(slug: "closed-login-temple")
      user = User.create!(
        email: "closed-login@example.com",
        english_name: "Closed Login",
        encrypted_password: User.password_hash("Password123!")
      )
      user.close_account!(reason: "self_service")

      post account_login_path, params: {
        temple: temple.slug,
        session: {
          email: user.email,
          password: "Password123!"
        }
      }

      assert_response :unprocessable_content
      assert_includes response.body, I18n.t("account.sessions.flash.account_closed")
    end

    test "closed account cannot complete central oauth sign in" do
      temple = create_temple(slug: "closed-oauth-temple")
      user = User.create!(
        email: "closed-oauth@example.com",
        english_name: "Closed OAuth",
        encrypted_password: User.password_hash("Password123!")
      )
      OAuthIdentity.create!(
        user: user,
        provider: "apple",
        provider_uid: "closed-oauth-apple",
        email: user.email,
        credentials: {},
        metadata: {}
      )
      user.close_account!(reason: "self_service")

      Auth::CentralOAuthClient.stub(:new, FakeCentralOAuthClient.new({ "redirect_url" => "https://auth.example.test/oauth" }, nil)) do
        get central_oauth_start_path(
          provider: "apple",
          surface: "account",
          temple: temple.slug,
          origin: account_login_path(temple: temple.slug)
        )
      end

      exchange_response = {
        "provider" => "apple",
        "uid" => "closed-oauth-apple",
        "email" => user.email,
        "email_verified" => true,
        "credentials" => { "token" => "apple-token" }
      }

      Auth::CentralOAuthClient.stub(:new, FakeCentralOAuthClient.new(nil, exchange_response)) do
        get central_oauth_callback_path(code: "oauth-code", state: "oauth-state")
      end

      assert_redirected_to account_login_path(temple: temple.slug)
      follow_redirect!
      assert_includes response.body, I18n.t("account.sessions.flash.account_closed")
    end
  end
end
