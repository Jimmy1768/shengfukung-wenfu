require "test_helper"

module Admin
  class AssistanceRequestsTest < ActionDispatch::IntegrationTest
    test "admin can view and close temple assistance requests" do
      temple = create_temple(slug: "assist-admin-temple")
      admin = create_admin_user(temple: temple, role: "owner")
      user = User.create!(
        email: "assist-admin-user@example.com",
        english_name: "Assist User",
        encrypted_password: User.password_hash("Password123!")
      )
      request_record = TempleAssistanceRequest.create!(
        temple: temple,
        user: user,
        status: "open",
        requested_at: Time.current,
        channel: "profile",
        message: "Please call me"
      )

      sign_in_admin(admin)

      get admin_assistance_requests_path

      assert_response :success
      assert_includes response.body, user.email
      assert_includes response.body, "Please call me"

      post close_admin_assistance_request_path(request_record)

      assert_redirected_to admin_assistance_requests_path
      request_record.reload
      assert_equal "closed", request_record.status
      assert_not_nil request_record.closed_at
      assert_equal admin.admin_account.id, request_record.closed_by_admin_id
      assert SystemAuditLog.exists?(action: "admin.assistance_requests.close", target: user)
    end
  end
end
