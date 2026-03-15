require "test_helper"

class InternalPrivacyRequestsTest < ActionDispatch::IntegrationTest
  test "configured operator can view privacy requests" do
    operator = create_operator!
    user = User.create!(
      email: "privacy-list@example.com",
      english_name: "Privacy List",
      encrypted_password: User.password_hash("Password123!")
    )
    PrivacyRequest.create!(
      user: user,
      request_type: "data_export",
      status: "pending",
      submitted_via: "web",
      requested_at: Time.current
    )

    with_env("INTERNAL_PLATFORM_OPERATOR_EMAIL" => "operator@example.com") do
      sign_in_admin(operator)

      get internal_privacy_requests_path

      assert_response :success
      assert_includes response.body, I18n.t("admin.internal.privacy_requests.index.title")
      assert_includes response.body, user.email
      assert_includes response.body, I18n.t("admin.internal.privacy_requests.shared.request_types.data_export")
    end
  end

  test "operator can approve and complete a privacy request" do
    operator = create_operator!
    user = User.create!(
      email: "privacy-transition@example.com",
      english_name: "Privacy Transition",
      encrypted_password: User.password_hash("Password123!")
    )
    request_record = PrivacyRequest.create!(
      user: user,
      request_type: "data_deletion",
      status: "pending",
      submitted_via: "web",
      requested_at: Time.current
    )

    with_env("INTERNAL_PLATFORM_OPERATOR_EMAIL" => "operator@example.com") do
      sign_in_admin(operator)

      post transition_internal_privacy_request_path(request_record, next_status: "approved")

      assert_redirected_to internal_privacy_requests_path
      assert_equal "approved", request_record.reload.status

      post transition_internal_privacy_request_path(request_record, next_status: "completed")

      assert_redirected_to internal_privacy_requests_path
      request_record.reload
      assert_equal "completed", request_record.status
      assert_not_nil request_record.resolved_at
      assert SystemAuditLog.exists?(action: "internal.privacy_requests.transition", target: user)
      assert AccountLifecycleEvent.exists?(user: user, event_type: "privacy_request_status_changed")
    end
  end

  test "completing a data export request generates downloadable export payload" do
    operator = create_operator!
    user = User.create!(
      email: "privacy-export@example.com",
      english_name: "Privacy Export",
      encrypted_password: User.password_hash("Password123!")
    )
    request_record = PrivacyRequest.create!(
      user: user,
      request_type: "data_export",
      status: "pending",
      submitted_via: "web",
      requested_at: Time.current
    )

    with_env("INTERNAL_PLATFORM_OPERATOR_EMAIL" => "operator@example.com") do
      sign_in_admin(operator)

      post transition_internal_privacy_request_path(request_record, next_status: "completed")

      assert_redirected_to internal_privacy_requests_path

      request_record.reload
      assert_equal "completed", request_record.status
      assert request_record.metadata["data_export_job_id"].present?
      assert request_record.metadata["data_export_payload_id"].present?

      payload = DataExportPayload.find(request_record.metadata["data_export_payload_id"])
      assert_equal request_record.id, payload.metadata.dig("payload", "privacy_requests")&.first&.fetch("id", nil)

      get export_internal_privacy_request_path(request_record)

      assert_response :success
      assert_equal "application/json", response.media_type
      json = JSON.parse(response.body)
      assert_equal user.email, json.dig("user", "email")
      assert_equal "data_export", json.dig("privacy_requests", 0, "request_type")
    end
  end

  test "completing a data deletion request anonymizes the account" do
    operator = create_operator!
    user = User.create!(
      email: "privacy-delete-fulfill@example.com",
      native_name: "王小明",
      english_name: "Wang",
      encrypted_password: User.password_hash("Password123!")
    )
    user.oauth_identities.create!(
      provider: "google_oauth2",
      provider_uid: "google-delete-uid",
      email: user.email,
      email_verified: true,
      linked_at: Time.current
    )
    request_record = PrivacyRequest.create!(
      user: user,
      request_type: "data_deletion",
      status: "approved",
      submitted_via: "web",
      requested_at: Time.current
    )

    with_env("INTERNAL_PLATFORM_OPERATOR_EMAIL" => "operator@example.com") do
      sign_in_admin(operator)

      post transition_internal_privacy_request_path(request_record, next_status: "completed")

      assert_redirected_to internal_privacy_requests_path

      user.reload
      request_record.reload
      assert_equal "completed", request_record.status
      assert_equal "closed", user.account_status
      assert_equal "deleted-user-#{user.id}@redacted.local", user.email
      assert_equal "已刪除使用者", user.native_name
      assert_equal "Deleted User", user.english_name
      assert_not_nil user.anonymized_at
      assert_equal 0, user.oauth_identities.count
      assert AccountLifecycleEvent.exists?(user: user, event_type: "account_anonymized")
    end
  end

  test "non-operator admin is redirected away from privacy requests" do
    temple = create_temple(slug: "privacy-no-access")
    user = create_admin_user(temple: temple, role: "owner")

    with_env("INTERNAL_PLATFORM_OPERATOR_EMAIL" => "operator@example.com") do
      sign_in_admin(user)

      get internal_privacy_requests_path

      assert_redirected_to admin_dashboard_path
    end
  end

  private

  def create_operator!(temple: create_temple(slug: "operator-temple", name: "Operator Temple"))
    operator = User.create!(
      email: "operator@example.com",
      encrypted_password: User.password_hash("Password123!"),
      english_name: "Operator"
    )
    admin_account = AdminAccount.create!(user: operator, active: true, role: "owner")
    AdminTempleMembership.create!(admin_account:, temple:, role: "owner")
    AdminPermission.create!(admin_account:, temple:, manage_permissions: true)
    operator
  end

  def with_env(overrides)
    original = overrides.transform_values { |_v| nil }
    overrides.each_key { |key| original[key] = ENV[key] }
    overrides.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    yield
  ensure
    original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end
