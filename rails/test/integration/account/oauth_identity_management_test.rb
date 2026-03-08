require "test_helper"

module Account
  class OauthIdentityManagementTest < ActionDispatch::IntegrationTest
    FakeCentralOAuthClient = Struct.new(:start_response, :exchange_response) do
      def start(**)
        start_response
      end

      def exchange(**)
        exchange_response
      end
    end

    test "signed in user can link another provider through central oauth callback" do
      temple = create_temple(slug: "oauth-linking-temple")
      user = User.create!(
        email: "link-owner@example.com",
        english_name: "Link Owner",
        encrypted_password: User.password_hash("Password123!"),
        metadata: {}
      )

      sign_in_account(user, temple_slug: temple.slug)

      AppConstants::OAuth.stub(:central_auth_enabled?, true) do
        post account_oauth_link_path(provider: "google")
        assert_redirected_to central_oauth_start_path(
          provider: "google",
          surface: "account",
          temple: temple.slug,
          origin: account_oauth_identities_path,
          intent: "link"
        )

        Auth::CentralOAuthClient.stub(:new, FakeCentralOAuthClient.new({ "redirect_url" => "https://auth.example.test/oauth" }, nil)) do
          follow_redirect!
        end

        assert_redirected_to "https://auth.example.test/oauth"
      end

      exchange_response = {
        "provider" => "google",
        "uid" => "google-linked-uid",
        "email" => "other-address@example.com",
        "email_verified" => true,
        "credentials" => { "token" => "linked-token" }
      }

      Auth::CentralOAuthClient.stub(:new, FakeCentralOAuthClient.new(nil, exchange_response)) do
        get central_oauth_callback_path(code: "oauth-code", state: "oauth-state")
      end

      assert_redirected_to account_oauth_identities_path
      follow_redirect!

      identity = OAuthIdentity.find_by!(provider: "google_oauth2", provider_uid: "google-linked-uid")
      assert_equal user.id, identity.user_id
      assert_includes response.body, "Google"
    end

    test "cannot link provider identity already attached to another user" do
      temple = create_temple(slug: "oauth-conflict-temple")
      current_user = User.create!(
        email: "current@example.com",
        english_name: "Current User",
        encrypted_password: User.password_hash("Password123!"),
        metadata: {}
      )
      other_user = User.create!(
        email: "other@example.com",
        english_name: "Other User",
        encrypted_password: User.password_hash("Password123!"),
        metadata: {}
      )
      OAuthIdentity.create!(
        user: other_user,
        provider: "google_oauth2",
        provider_uid: "shared-provider-uid",
        email: "other@example.com",
        credentials: {},
        metadata: {}
      )

      sign_in_account(current_user, temple_slug: temple.slug)

      AppConstants::OAuth.stub(:central_auth_enabled?, true) do
        post account_oauth_link_path(provider: "google")
        Auth::CentralOAuthClient.stub(:new, FakeCentralOAuthClient.new({ "redirect_url" => "https://auth.example.test/oauth" }, nil)) do
          follow_redirect!
        end
      end

      exchange_response = {
        "provider" => "google",
        "uid" => "shared-provider-uid",
        "email" => "other@example.com",
        "email_verified" => true,
        "credentials" => { "token" => "conflict-token" }
      }

      Auth::CentralOAuthClient.stub(:new, FakeCentralOAuthClient.new(nil, exchange_response)) do
        get central_oauth_callback_path(code: "oauth-code", state: "oauth-state")
      end

      assert_redirected_to account_oauth_identities_path
      follow_redirect!

      identity = OAuthIdentity.find_by!(provider: "google_oauth2", provider_uid: "shared-provider-uid")
      assert_equal other_user.id, identity.user_id
      assert_includes response.body, "already linked to another account"
    end

    test "user can unlink provider when another login path remains" do
      temple = create_temple(slug: "oauth-unlink-temple")
      user = User.create!(
        email: "unlink@example.com",
        english_name: "Unlink User",
        encrypted_password: User.password_hash("Password123!"),
        metadata: {}
      )
      identity = OAuthIdentity.create!(
        user: user,
        provider: "google_oauth2",
        provider_uid: "unlink-google-uid",
        email: user.email,
        credentials: {},
        metadata: {}
      )

      sign_in_account(user, temple_slug: temple.slug)

      delete account_oauth_unlink_path(provider: "google")

      assert_redirected_to account_oauth_identities_path
      assert_nil OAuthIdentity.find_by(id: identity.id)
    end

    test "oauth seeded user cannot unlink last provider" do
      temple = create_temple(slug: "oauth-last-method-temple")
      user = User.create!(
        email: "oauth-only@example.com",
        english_name: "OAuth Only",
        encrypted_password: User.password_hash("Password123!"),
        metadata: { "oauth_seeded" => true }
      )
      identity = OAuthIdentity.create!(
        user: user,
        provider: "google_oauth2",
        provider_uid: "oauth-only-google-uid",
        email: user.email,
        credentials: {},
        metadata: {}
      )

      sign_in_account(user, temple_slug: temple.slug)

      delete account_oauth_unlink_path(provider: "google")

      assert_redirected_to account_oauth_identities_path
      assert OAuthIdentity.exists?(identity.id)
      follow_redirect!
      assert_includes response.body, "Add another sign-in method before unlinking this provider."
    end
  end
end
