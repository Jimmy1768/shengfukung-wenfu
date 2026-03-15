# frozen_string_literal: true

require "test_helper"

class Account::Api::PreferencesTest < ActionDispatch::IntegrationTest
  test "shows persisted preference payload for signed-in user" do
    temple = create_temple
    user = create_admin_user(temple:, role: "admin")
    preference = UserPreference.for_user(user)
    preference.set_display_mode(:account, "dark")
    preference.set_display_mode(:admin, "standard")
    preference.set_mobile_theme_id("temple-2")
    preference.save!

    sign_in_account(user, temple_slug: temple.slug)
    get api_v1_account_preferences_path

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal "dark", payload.dig("preferences", "account_display_mode")
    assert_equal "standard", payload.dig("preferences", "admin_display_mode")
    assert_equal "temple-2", payload.dig("preferences", "mobile_theme_id")
  end

  test "updates preferences and writes audit log" do
    temple = create_temple
    user = create_admin_user(temple:, role: "owner")

    sign_in_account(user, temple_slug: temple.slug)

    assert_difference("SystemAuditLog.count", 1) do
      patch api_v1_account_preferences_path, params: {
        preferences: {
          account_display_mode: "dark",
          admin_display_mode: "dark",
          mobile_theme_id: "temple-2"
        }
      }
    end

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal "dark", payload.dig("preferences", "account_display_mode")
    assert_equal "dark", payload.dig("preferences", "admin_display_mode")
    assert_equal "temple-2", payload.dig("preferences", "mobile_theme_id")

    preference = user.reload.user_preference
    assert_equal "dark", preference.display_mode_for(:account)
    assert_equal "dark", preference.display_mode_for(:admin)
    assert_equal "temple-2", preference.mobile_theme_id
  end

  test "rejects invalid preference values" do
    temple = create_temple
    user = create_admin_user(temple:, role: "admin")

    sign_in_account(user, temple_slug: temple.slug)

    patch api_v1_account_preferences_path, params: {
      preferences: {
        account_display_mode: "invalid",
        mobile_theme_id: "ops-dark"
      }
    }

    assert_response :unprocessable_entity
    payload = JSON.parse(response.body)
    assert_equal "invalid_preferences", payload["error"]
    assert_includes payload["details"], "account_display_mode"
    assert_includes payload["details"], "mobile_theme_id"
  end
end
