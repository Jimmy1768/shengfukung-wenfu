require "test_helper"

module Account
  class PrivacyFlowTest < ActionDispatch::IntegrationTest
    test "signed in user can request data deletion" do
      temple = create_temple(slug: "privacy-delete-temple")
      user = User.create!(
        email: "privacy-delete@example.com",
        english_name: "Privacy Delete",
        encrypted_password: User.password_hash("Password123!")
      )

    sign_in_account(user, temple_slug: temple.slug)

      assert_difference -> { SystemAuditLog.where(action: "account.privacy.requested").count }, 1 do
        post request_data_deletion_account_privacy_path
      end

      assert_redirected_to account_privacy_path
      request_record = PrivacyRequest.find_by!(user: user, request_type: "data_deletion")
      assert_equal "pending", request_record.status
      assert AccountLifecycleEvent.exists?(user: user, event_type: "privacy_request_submitted")
    end

    test "signed in user can request data export" do
      temple = create_temple(slug: "privacy-export-temple")
      user = User.create!(
        email: "privacy-export@example.com",
        english_name: "Privacy Export",
        encrypted_password: User.password_hash("Password123!")
      )

    sign_in_account(user, temple_slug: temple.slug)

      assert_difference -> { SystemAuditLog.where(action: "account.privacy.requested").count }, 1 do
        post request_data_export_account_privacy_path
      end

      assert_redirected_to account_privacy_path
      request_record = PrivacyRequest.find_by!(user: user, request_type: "data_export")
      assert_equal "pending", request_record.status
    end

    test "signed in user cannot create duplicate open privacy request" do
      temple = create_temple(slug: "privacy-duplicate-temple")
      user = User.create!(
        email: "privacy-duplicate@example.com",
        english_name: "Privacy Duplicate",
        encrypted_password: User.password_hash("Password123!")
      )
      PrivacyRequest.create!(
        user: user,
        request_type: "data_export",
        status: "pending",
        submitted_via: "web",
        requested_at: Time.current
      )

      sign_in_account(user, temple_slug: temple.slug)

      post request_data_export_account_privacy_path

      assert_redirected_to account_privacy_path
      follow_redirect!
      assert_includes response.body, I18n.t("account.privacy.flash.request_already_open")
      assert_equal 1, PrivacyRequest.where(user: user, request_type: "data_export").count
    end

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

      assert_difference -> { SystemAuditLog.where(action: "account.privacy.account_closed").count }, 1 do
        post close_account_privacy_path
      end

      assert_redirected_to account_login_path
      user.reload
      assert_equal "closed", user.account_status

      request_record = PrivacyRequest.find_by!(user: user, request_type: "account_closure")
      assert_equal "completed", request_record.status
      log = SystemAuditLog.order(created_at: :desc).find_by(action: "account.privacy.account_closed")
      assert_equal "account_closure", log.metadata["request_type"]

      get account_dashboard_path
      assert_redirected_to account_temples_path
    end
  end
end
