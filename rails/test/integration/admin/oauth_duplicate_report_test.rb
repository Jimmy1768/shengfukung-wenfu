require "test_helper"

module Admin
  class OauthDuplicateReportTest < ActionDispatch::IntegrationTest
    test "owner can review duplicate oauth candidates report" do
      temple = create_temple(slug: "duplicate-report-temple")
      admin_user = create_admin_user(temple: temple)

      first_user = User.create!(
        email: "first@example.com",
        english_name: "First User",
        encrypted_password: User.password_hash("Password123!"),
        metadata: {}
      )
      second_user = User.create!(
        email: "second@example.com",
        english_name: "Second User",
        encrypted_password: User.password_hash("Password123!"),
        metadata: {}
      )

      OAuthIdentity.create!(
        user: first_user,
        provider: "google_oauth2",
        provider_uid: "dup-google",
        email: "shared@example.com",
        email_verified: true,
        credentials: {},
        metadata: {}
      )
      OAuthIdentity.create!(
        user: second_user,
        provider: "apple",
        provider_uid: "dup-apple",
        email: "shared@example.com",
        email_verified: true,
        credentials: {},
        metadata: {}
      )

      sign_in_admin(admin_user)

      get oauth_duplicates_admin_patrons_path

      assert_response :success
      assert_includes response.body, "shared@example.com"
      assert_includes response.body, "First User"
      assert_includes response.body, "Second User"
    end
  end
end
