require "test_helper"

module Account
  class PrivacyFlowTest < ActionDispatch::IntegrationTest
    test "signed in user can close account from privacy page" do
      temple = create_temple(slug: "privacy-flow-temple")
      user = User.create!(
        email: "privacy-flow@example.com",
        english_name: "Privacy Flow",
        encrypted_password: User.password_hash("Password123!")
      )

      sign_in_account(user, temple_slug: temple.slug)

      get account_privacy_path
      assert_response :success
      assert_includes response.body, I18n.t("account.privacy.close_account.title")

      post close_account_privacy_path

      assert_redirected_to account_login_path
      user.reload
      assert_equal "closed", user.account_status

      request_record = PrivacyRequest.find_by!(user: user, request_type: "account_closure")
      assert_equal "completed", request_record.status

      get account_dashboard_path
      assert_redirected_to account_temples_path
    end
  end
end
