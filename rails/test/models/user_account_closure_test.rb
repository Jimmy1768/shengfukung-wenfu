require "test_helper"

class UserAccountClosureTest < ActiveSupport::TestCase
  test "close_account! marks lifecycle state and revokes linked access" do
    user = User.create!(
      email: "closure-model@example.com",
      english_name: "Closure Model",
      encrypted_password: User.password_hash("Password123!")
    )

    refresh_token = RefreshToken.create!(
      user: user,
      token_digest: SecureRandom.hex(16),
      expires_at: 30.days.from_now
    )
    push_token = PushToken.create!(
      user: user,
      platform: "ios",
      token: "push-token-123"
    )
    oauth_identity = OAuthIdentity.create!(
      user: user,
      provider: "google_oauth2",
      provider_uid: "closure-model-google",
      email: user.email,
      credentials: {},
      metadata: {}
    )

    user.close_account!(reason: "self_service")
    user.reload

    assert_equal "closed", user.account_status
    assert_equal "self_service", user.closure_reason
    assert_not_nil user.closed_at
    assert refresh_token.reload.revoked
    assert_not push_token.reload.active
    assert_equal "self_service", oauth_identity.reload.metadata["revoked_reason"]
    assert AccountLifecycleEvent.exists?(user: user, event_type: "account_closed")
  end
end
