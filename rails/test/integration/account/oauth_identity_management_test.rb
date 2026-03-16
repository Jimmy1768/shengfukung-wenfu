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

    setup do
      Config::EntryResolver.upsert!(key: "oauth_account_linking", value: true)
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
        assert SystemAuditLog.exists?(action: "account.oauth.link_started", target: user)
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

    test "signed in user can link apple through central oauth callback" do
      temple = create_temple(slug: "oauth-apple-linking-temple")
      user = User.create!(
        email: "apple-link-owner@example.com",
        english_name: "Apple Link Owner",
        encrypted_password: User.password_hash("Password123!"),
        metadata: {}
      )

      sign_in_account(user, temple_slug: temple.slug)

      AppConstants::OAuth.stub(:central_auth_enabled?, true) do
        post account_oauth_link_path(provider: "apple")
        assert_redirected_to central_oauth_start_path(
          provider: "apple",
          surface: "account",
          temple: temple.slug,
          origin: account_oauth_identities_path,
          intent: "link"
        )

        Auth::CentralOAuthClient.stub(:new, FakeCentralOAuthClient.new({ "redirect_url" => "https://auth.example.test/apple" }, nil)) do
          follow_redirect!
        end

        assert_redirected_to "https://auth.example.test/apple"
        assert SystemAuditLog.exists?(action: "account.oauth.link_started", target: user)
      end

      exchange_response = {
        "provider" => "apple",
        "uid" => "apple-linked-uid",
        "email" => "apple-private-relay@example.com",
        "email_verified" => true,
        "credentials" => { "token" => "apple-linked-token" }
      }

      Auth::CentralOAuthClient.stub(:new, FakeCentralOAuthClient.new(nil, exchange_response)) do
        get central_oauth_callback_path(code: "apple-oauth-code", state: "apple-oauth-state")
      end

      assert_redirected_to account_oauth_identities_path
      follow_redirect!

      identity = OAuthIdentity.find_by!(provider: "apple", provider_uid: "apple-linked-uid")
      assert_equal user.id, identity.user_id
      assert_includes response.body, "Apple"
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
      assert SystemAuditLog.exists?(action: "account.oauth.link_conflict", target: current_user)
    end

    test "oauth sign in without usable name redirects to profile edit" do
      temple = create_temple(slug: "oauth-profile-temple")

      Auth::CentralOAuthClient.stub(:new, FakeCentralOAuthClient.new({ "redirect_url" => "https://auth.example.test/oauth" }, nil)) do
        get central_oauth_start_path(
          provider: "apple",
          surface: "account",
          temple: temple.slug,
          origin: account_login_path(temple: temple.slug)
        )
      end

      assert_redirected_to "https://auth.example.test/oauth"

      exchange_response = {
        "provider" => "apple",
        "uid" => "apple-missing-name-uid",
        "email" => "apple-missing-name@example.com",
        "email_verified" => true,
        "credentials" => { "token" => "apple-token" }
      }

      Auth::CentralOAuthClient.stub(:new, FakeCentralOAuthClient.new(nil, exchange_response)) do
        get central_oauth_callback_path(code: "oauth-code", state: "oauth-state")
      end

      assert_redirected_to edit_account_profile_path
      follow_redirect!

      assert_response :success
      assert_includes response.body, I18n.t("account.oauth.flash.complete_profile")

      user = User.find_by!(email: "apple-missing-name@example.com")
      assert_equal user.id, session[AppConstants::Sessions.key(:account)]
      assert_equal "OAuth User", user.english_name
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
      assert SystemAuditLog.exists?(action: "account.oauth.unlinked", target: user)
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

    test "link management is unavailable when feature flag is off" do
      temple = create_temple(slug: "oauth-flag-off-temple")
      user = User.create!(
        email: "flag-off@example.com",
        english_name: "Flag Off",
        encrypted_password: User.password_hash("Password123!"),
        metadata: {}
      )

      sign_in_account(user, temple_slug: temple.slug)
      Config::EntryResolver.upsert!(key: "oauth_account_linking", value: false)

      get account_oauth_identities_path

      assert_redirected_to account_profile_path
    end
  end
end
