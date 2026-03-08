require "test_helper"

module Admin
  class OAuthDuplicateCandidatesReportTest < ActiveSupport::TestCase
    test "returns verified email groups linked to multiple users" do
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
      OAuthIdentity.create!(
        user: second_user,
        provider: "facebook",
        provider_uid: "unique-facebook",
        email: "unique@example.com",
        email_verified: true,
        credentials: {},
        metadata: {}
      )

      entry = OAuthDuplicateCandidatesReport.new.entries.first

      assert_equal "shared@example.com", entry.verified_email
      assert_equal [first_user.id, second_user.id].sort, entry.user_ids.sort
      assert_equal %w[apple google_oauth2], entry.providers.sort
    end
  end
end
