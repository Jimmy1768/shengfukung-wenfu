require "test_helper"

module Auth
  class OAuthIdentityResolverTest < ActiveSupport::TestCase
    test "creates identity and user when no existing records match" do
      result = OAuthIdentityResolver.resolve_or_link!(
        provider: "google_oauth2",
        uid: "resolver-new-uid",
        email: "resolver.new@example.com",
        name: "Resolver New",
        email_verified: true,
        credentials: { "token" => "abc" },
        metadata: { "source" => "test" }
      )

      assert result.identity.persisted?
      assert result.user.persisted?
      assert_equal result.user.id, result.identity.user_id
      assert_equal "resolver.new@example.com", result.identity.email
      assert_equal true, result.created_identity
      assert_equal false, result.linked_existing_user
      assert_equal "abc", result.identity.credentials["token"]
      assert_equal "test", result.identity.metadata["source"]
    end

    test "links identity to existing user by email" do
      user = create_user("resolver.link@example.com", "Resolver Link")

      result = OAuthIdentityResolver.resolve_or_link!(
        provider: "facebook",
        uid: "resolver-link-uid",
        email: user.email,
        name: "Ignored Name",
        email_verified: true,
        credentials: {},
        metadata: { "source" => "test-link" }
      )

      assert_equal user.id, result.user.id
      assert_equal user.id, result.identity.user_id
      assert_equal true, result.linked_existing_user
      assert_equal true, result.created_identity
    end

    test "reuses existing identity for provider and uid" do
      first = OAuthIdentityResolver.resolve_or_link!(
        provider: "apple",
        uid: "resolver-existing-uid",
        email: "resolver.existing@example.com",
        name: "Resolver Existing",
        credentials: { "token" => "first" },
        metadata: { "source" => "first" }
      )

      second = OAuthIdentityResolver.resolve_or_link!(
        provider: "apple",
        uid: "resolver-existing-uid",
        email: "resolver.existing@example.com",
        name: "Resolver Existing",
        credentials: { "token" => "second" },
        metadata: { "source" => "second" }
      )

      assert_equal first.identity.id, second.identity.id
      assert_equal first.user.id, second.user.id
      assert_equal false, second.created_identity
      assert_equal "second", second.identity.credentials["token"]
      assert_equal "second", second.identity.metadata["source"]
    end

    private

    def create_user(email, name)
      User.create!(
        email: email,
        english_name: name,
        encrypted_password: User.password_hash("Resolver!123"),
        metadata: {}
      )
    end
  end
end
