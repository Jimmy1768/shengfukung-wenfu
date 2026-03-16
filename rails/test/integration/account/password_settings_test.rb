require "test_helper"

class AccountPasswordSettingsTest < ActionDispatch::IntegrationTest
  test "signup collision shows guidance for existing oauth-first account" do
    temple = create_temple(slug: "shengfukung-wenfu")
    user = User.create!(
      email: "oauth-user@example.com",
      english_name: "OAuth User",
      encrypted_password: User.password_hash(SecureRandom.hex(16)),
      metadata: { "oauth_seeded" => true }
    )
    OAuthIdentity.create!(
      user: user,
      provider: "google_oauth2",
      provider_uid: "google-123",
      email: user.email,
      credentials: {},
      metadata: {}
    )

    post account_register_path, params: {
      temple: temple.slug,
      after_sign_in: "settings",
      registration: {
        email: "oauth-user@example.com",
        password: "Password123!",
        password_confirmation: "Password123!"
      }
    }

    assert_response :unprocessable_content
    assert_includes response.body, I18n.t("account.signups.form.existing_account_guidance")
    assert_includes response.body, "Google"
    assert_includes response.body, I18n.t("account.sessions.new.social.existing_account_settings_hint")
  end

  test "signed-in oauth-first user can add password from settings" do
    temple = create_temple(slug: "shengfukung-wenfu")
    user = User.create!(
      email: "oauth-settings@example.com",
      english_name: "OAuth Settings User",
      encrypted_password: User.password_hash("OAuthSeeded!123"),
      metadata: { "oauth_seeded" => true }
    )

    sign_in_account(user, password: "OAuthSeeded!123", temple_slug: temple.slug)
    get account_settings_path
    assert_response :success
    assert_includes response.body, I18n.t("account.settings.password.title")

    assert_difference -> { SystemAuditLog.where(action: "account.password.added").count }, 1 do
      patch account_settings_path, params: {
        account_password_settings_form: {
          password: "Password123!",
          password_confirmation: "Password123!"
        }
      }
    end

    assert_redirected_to account_settings_path
    user.reload
    assert_equal User.password_hash("Password123!"), user.encrypted_password
    assert_equal false, user.metadata["oauth_seeded"]
    log = SystemAuditLog.order(created_at: :desc).find_by(action: "account.password.added")
    assert_equal user, log.user
    assert_equal temple, log.temple
    assert_equal "account_settings", log.metadata["source"]

    sign_in_account(user, password: "Password123!", temple_slug: temple.slug)
    assert_response :success
    assert_includes response.body, user.english_name
  end
end
