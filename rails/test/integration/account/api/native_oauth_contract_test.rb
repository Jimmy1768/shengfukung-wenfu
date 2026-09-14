# frozen_string_literal: true

require "test_helper"
require "base64"
require "json"

class NativeOauthContractTest < ActionDispatch::IntegrationTest
  FakeCentralOAuthClient = Struct.new(:start_response, :exchange_response, :start_error, :exchange_error) do
    attr_reader :start_calls, :exchange_calls

    def start(**arguments)
      (@start_calls ||= []) << arguments
      raise start_error if start_error
      start_response
    end

    def exchange(**arguments)
      (@exchange_calls ||= []) << arguments
      raise exchange_error if exchange_error
      exchange_response
    end
  end

  def setup
    @temple = create_temple(slug: "native-oauth-temple")
    Config::EntryResolver.upsert!(key: "oauth_account_resolution", value: true)
    @return_url = "templemate://oauth/complete"
    @verifier = "v" * 43
    @challenge = Auth::NativeOAuthTransaction.s256_challenge(@verifier)
  end

  # Criterion 6. A patron with no temple loaded signs in by Google and Apple,
  # not only by email. The flow read @temple.slug for both the transaction and
  # the central tenant, so a temple-less start raised NoMethodError through a
  # rescue list that did not cover it.
  test "OAuth starts with no temple loaded" do
    central = FakeCentralOAuthClient.new({ "redirect_url" => "https://central.example.test/google" }, nil)

    with_return_url do
      Auth::CentralOAuthClient.stub(:new, central) do
        post native_start_path, params: start_params(provider: "google")
      end
    end

    assert_response :created
    assert_equal "google", response.parsed_body.fetch("oauth").fetch("provider")
    assert response.parsed_body.fetch("oauth").fetch("transaction_token").present?
    assert_equal "shengfukung", central.start_calls.first.fetch(:tenant_slug)
    refute_includes central.start_calls.first.to_s, "native-oauth-temple",
      "no temple may reach the central client"
  end

  # A transaction is deliberately no longer bound to a temple. It carried
  # temple_slug and refused an exchange presented under a different one; that
  # guarded a session's temple scope, and a session no longer has one. What the
  # transaction still binds is unchanged and asserted above: the token itself,
  # the return URL, the PKCE verifier and the provider.
  test "a transaction is not bound to a temple" do
    central = FakeCentralOAuthClient.new({ "redirect_url" => "https://central.example.test/google" }, identity_response)
    token = start_transaction(central)

    with_return_url do
      Auth::CentralOAuthClient.stub(:new, central) do
        post native_exchange_path(temple_slug: create_temple.slug), params: exchange_params(token)
      end
    end

    refute_equal 401, response.status, "a different temple must not invalidate the transaction"
    assert_equal "account_resolution_required", response.parsed_body.fetch("code")
  end

  test "Google start uses only server selected return URL and exact S256 arguments" do
    central = FakeCentralOAuthClient.new({ "redirect_url" => "https://central.example.test/google" }, nil)

    with_return_url do
      Auth::CentralOAuthClient.stub(:new, central) do
        post native_start_path, params: start_params(provider: "google").merge(return_url: "https://attacker.test", origin: "https://attacker.test", surface: "admin")
      end
    end

    assert_response :created
    oauth = response.parsed_body.fetch("oauth")
    assert_equal "google", oauth.fetch("provider")
    assert_equal @return_url, oauth.fetch("redirect_uri")
    assert_equal "https://central.example.test/google", oauth.fetch("authorization_url")
    refute_includes response.body, @challenge
    assert_equal [
      {
        provider: "google",
        return_url: @return_url,
        # The deployment's central tenant, not this temple's slug. Nothing about
        # signing in varies by temple, and a patron may have none loaded.
        tenant_slug: "shengfukung",
        pkce_challenge: @challenge,
        pkce_method: "S256",
        context: { "native_oauth_contract" => "v1" }
      }
    ], central.start_calls
  end

  test "Apple exchange creates only account scoped native session and redacts central credentials" do
    dual_role_user = create_admin_user(temple: @temple)
    OAuthIdentity.create!(user: dual_role_user, provider: "apple", provider_uid: "apple-native-subject", email: dual_role_user.email, credentials: {}, metadata: {})
    central = FakeCentralOAuthClient.new(
      { "redirect_url" => "https://central.example.test/apple" },
      identity_response(provider: "apple", uid: "apple-native-subject", email: dual_role_user.email, name: "Admin User", token: "provider-secret-token")
    )
    transaction_token = start_transaction(central, provider: "apple")

    with_return_url do
      Auth::CentralOAuthClient.stub(:new, central) do
        post native_exchange_path, params: exchange_params(transaction_token)
      end
    end

    assert_response :success
    body = response.parsed_body
    assert_equal "apple", body.dig("oauth", "provider")
    assert_equal false, body.dig("oauth", "profile_required")
    assert_not body.fetch("user").key?("admin_account")
    assert_not_includes response.body, "provider-secret-token"
    assert_not_includes response.body, "apple-native-subject"
    claims = Auth::JwtService.decode(body.dig("session", "access_token"))
    assert_equal "account", claims.fetch("scope")
    assert_equal dual_role_user.id, claims.fetch("sub")
    assert_nil session[AppConstants::Sessions.key(:account)]
    assert_equal @return_url, central.exchange_calls.fetch(0).dig(:params, :return_url)
    assert_equal @verifier, central.exchange_calls.fetch(0).dig(:params, :pkce_verifier)
    assert_equal "apple", central.exchange_calls.fetch(0).dig(:params, :provider)
  end

  test "existing identity and profile-required outcomes reuse resolver semantics" do
    user = User.create!(email: "existing-native@example.test", english_name: "Existing Native", encrypted_password: User.password_hash("Password123!"), metadata: {})
    OAuthIdentity.create!(user:, provider: "google_oauth2", provider_uid: "existing-google-subject", email: user.email, credentials: {}, metadata: {})
    central = FakeCentralOAuthClient.new({ "redirect_url" => "https://central.example.test/google" }, identity_response(provider: "google", uid: "existing-google-subject", email: user.email, name: "Existing Native"))

    token = start_transaction(central, provider: "google")
    with_return_url { Auth::CentralOAuthClient.stub(:new, central) { post native_exchange_path, params: exchange_params(token) } }
    assert_response :success
    assert_equal user.id, response.parsed_body.dig("user", "id")
    assert_equal false, response.parsed_body.dig("oauth", "profile_required")

    profile_central = FakeCentralOAuthClient.new({ "redirect_url" => "https://central.example.test/apple" }, identity_response(provider: "apple", uid: "profile-apple-subject", email: "profile-native@example.test", name: nil))
    profile_token = start_transaction(profile_central, provider: "apple")
    with_return_url { Auth::CentralOAuthClient.stub(:new, profile_central) { post native_exchange_path, params: exchange_params(profile_token) } }
    assert_response :conflict
    assert_equal "account_resolution_required", response.parsed_body.fetch("code")
    assert_nil response.parsed_body["session"]
    assert response.parsed_body.dig("oauth", "resolution_token").present?
    assert_nil session[AppConstants::Sessions.key(:account)]
  end

  # The provider already told us who this is; making the patron retype it is
  # the friction the resolution screen exists to avoid.
  test "the resolution conflict carries the provider's name and email for prefill" do
    central = FakeCentralOAuthClient.new(
      { "redirect_url" => "https://central.example.test/google" },
      identity_response(provider: "google", uid: "prefill-subject",
                        email: "prefill-native@example.test", name: "Lin Xiao An")
    )
    token = start_transaction(central)

    with_return_url { Auth::CentralOAuthClient.stub(:new, central) { post native_exchange_path, params: exchange_params(token) } }

    assert_response :conflict
    assert_equal "account_resolution_required", response.parsed_body.fetch("code")
    oauth = response.parsed_body.fetch("oauth")
    assert oauth.fetch("resolution_token").present?
    assert_equal "Lin Xiao An", oauth.fetch("name")
    assert_equal "prefill-native@example.test", oauth.fetch("email")

    # Still only hints: no session is issued and nothing is authenticated yet.
    assert_nil response.parsed_body["session"]
    assert_nil session[AppConstants::Sessions.key(:account)]
  end

  test "a provider that supplies no name yields a nil hint rather than a placeholder" do
    central = FakeCentralOAuthClient.new(
      { "redirect_url" => "https://central.example.test/apple" },
      identity_response(provider: "apple", uid: "no-name-subject",
                        email: "no-name@example.test", name: nil)
    )
    token = start_transaction(central, provider: "apple")

    with_return_url { Auth::CentralOAuthClient.stub(:new, central) { post native_exchange_path, params: exchange_params(token) } }

    assert_response :conflict
    assert_nil response.parsed_body.dig("oauth", "name")
  end

  test "native exchange uses shared nested Google claims and Apple id-token fallbacks" do
    google = FakeCentralOAuthClient.new(
      { "redirect_url" => "https://central.example.test/google" },
      {
        "claims" => {
          "provider" => "google",
          "sub" => "nested-google-subject",
          "email" => "nested-google@example.test",
          "name" => "Nested Google",
          "email_verified" => true
        },
        "credentials" => { "token" => "central-token" }
      }
    )
    google_token = start_transaction(google, provider: "google")
    with_return_url { Auth::CentralOAuthClient.stub(:new, google) { post native_exchange_path, params: exchange_params(google_token) } }
    assert_response :conflict
    assert_equal "google", response.parsed_body.dig("oauth", "provider")
    refute OAuthIdentity.exists?(provider: "google_oauth2", provider_uid: "nested-google-subject")

    apple = FakeCentralOAuthClient.new(
      { "redirect_url" => "https://central.example.test/apple" },
      {
        "identity" => { "provider" => "apple" },
        "credentials" => { "id_token" => id_token(sub: "nested-apple-subject", email: "nested-apple@example.test") }
      }
    )
    apple_token = start_transaction(apple, provider: "apple")
    with_return_url { Auth::CentralOAuthClient.stub(:new, apple) { post native_exchange_path, params: exchange_params(apple_token) } }
    assert_response :conflict
    assert_equal "apple", response.parsed_body.dig("oauth", "provider")
    refute OAuthIdentity.exists?(provider: "apple", provider_uid: "nested-apple-subject")
  end

  test "a verified email user is not linked without an explicit proof flow" do
    user = User.create!(email: "verified-link@example.test", english_name: "Verified Link", encrypted_password: User.password_hash("Password123!"), metadata: {})
    central = FakeCentralOAuthClient.new(
      { "redirect_url" => "https://central.example.test/google" },
      identity_response(provider: "google", uid: "verified-link-subject", email: user.email, name: "Verified Link")
    )
    token = start_transaction(central)

    with_return_url { Auth::CentralOAuthClient.stub(:new, central) { post native_exchange_path, params: exchange_params(token) } }

    assert_response :conflict
    assert_equal "account_resolution_required", response.parsed_body.fetch("code")
    assert_nil OAuthIdentity.find_by(provider: "google_oauth2", provider_uid: "verified-link-subject")
  end

  test "start rejects unsupported or malformed input missing configuration unknown temple and ignores client redirect fields" do
    post native_start_path, params: start_params(provider: "facebook")
    assert_response :unprocessable_entity
    assert_equal "unsupported_oauth_provider", response.parsed_body.fetch("code")

    post native_start_path, params: start_params(pkce_method: "plain")
    assert_response :unprocessable_entity
    assert_equal "invalid_pkce", response.parsed_body.fetch("code")

    post native_start_path, params: { temple_slug: @temple.slug, oauth: { provider: "google", pkce_challenge: @challenge, pkce_method: "S256" } }
    assert_response :service_unavailable
    assert_equal "native_oauth_unavailable", response.parsed_body.fetch("code")

    with_return_url do
      post native_start_path(temple_slug: "not-a-temple"), params: { oauth: { provider: "google", pkce_challenge: @challenge, pkce_method: "S256" } }
    end
    assert_response :not_found
    assert_equal "tenant_not_found", response.parsed_body.fetch("code")
  end

  test "exchange rejects tamper changed return verifier mismatch and provider mismatch without a session" do
    central = FakeCentralOAuthClient.new({ "redirect_url" => "https://central.example.test/google" }, identity_response)
    token = start_transaction(central)

    with_return_url do
      Auth::CentralOAuthClient.stub(:new, central) do
        post native_exchange_path, params: exchange_params("#{token}x")
        assert_response :unauthorized
        assert_equal "invalid_oauth_transaction", response.parsed_body.fetch("code")

        post native_exchange_path, params: exchange_params(token, verifier: "x" * 43)
        assert_response :unauthorized
        assert_equal "invalid_oauth_transaction", response.parsed_body.fetch("code")
      end
    end
    assert_empty central.exchange_calls.to_a
    assert_nil session[AppConstants::Sessions.key(:account)]

    mismatch = FakeCentralOAuthClient.new({ "redirect_url" => "https://central.example.test/google" }, identity_response(provider: "apple", uid: "mismatch"))
    mismatch_token = start_transaction(mismatch)
    with_return_url { Auth::CentralOAuthClient.stub(:new, mismatch) { post native_exchange_path, params: exchange_params(mismatch_token) } }
    assert_response :unprocessable_entity
    assert_equal "oauth_provider_mismatch", response.parsed_body.fetch("code")
    assert_nil session[AppConstants::Sessions.key(:account)]
  end

  test "exchange rejects a missing code before contacting central auth" do
    central = FakeCentralOAuthClient.new({ "redirect_url" => "https://central.example.test/google" }, identity_response)
    token = start_transaction(central)

    with_return_url do
      Auth::CentralOAuthClient.stub(:new, central) do
        post native_exchange_path, params: exchange_params(token).deep_merge(oauth: { code: "" })
      end
    end

    assert_response :unprocessable_entity
    assert_equal "invalid_oauth_grant", response.parsed_body.fetch("code")
    assert_empty central.exchange_calls.to_a
    assert_nil session[AppConstants::Sessions.key(:account)]
  end

  test "central start exchange malformed invalid grant replay and closed account fail without a session" do
    malformed_start = FakeCentralOAuthClient.new({}, nil)
    with_return_url { Auth::CentralOAuthClient.stub(:new, malformed_start) { post native_start_path, params: start_params } }
    assert_response :bad_gateway
    assert_equal "oauth_start_failed", response.parsed_body.fetch("code")

    central_failure = FakeCentralOAuthClient.new({ "redirect_url" => "https://central.example.test/google" }, nil, nil, Auth::CentralOAuthClient::RequestError.new(code: "invalid_grant"))
    failure_token = start_transaction(central_failure)
    with_return_url { Auth::CentralOAuthClient.stub(:new, central_failure) { post native_exchange_path, params: exchange_params(failure_token) } }
    assert_response :unprocessable_entity
    assert_equal "invalid_oauth_grant", response.parsed_body.fetch("code")
    assert_not_includes response.body, "provider-body"

    generic_failure = FakeCentralOAuthClient.new(
      { "redirect_url" => "https://central.example.test/google" },
      nil,
      nil,
      Auth::CentralOAuthClient::RequestError.new("arbitrary-upstream-detail")
    )
    generic_token = start_transaction(generic_failure)
    with_return_url { Auth::CentralOAuthClient.stub(:new, generic_failure) { post native_exchange_path, params: exchange_params(generic_token) } }
    assert_response :bad_gateway
    assert_equal "oauth_exchange_failed", response.parsed_body.fetch("code")
    assert_not_includes response.body, "arbitrary-upstream-detail"

    replay_user = User.create!(email: "native-oauth@example.test", english_name: "Native OAuth", encrypted_password: User.password_hash("Password123!"), metadata: {})
    OAuthIdentity.create!(user: replay_user, provider: "google_oauth2", provider_uid: "google-native-subject", email: replay_user.email, credentials: {}, metadata: {})
    replay = FakeCentralOAuthClient.new({ "redirect_url" => "https://central.example.test/google" }, identity_response)
    replay_token = start_transaction(replay)
    with_return_url { Auth::CentralOAuthClient.stub(:new, replay) { post native_exchange_path, params: exchange_params(replay_token) } }
    assert_response :success
    replay.exchange_error = Auth::CentralOAuthClient::RequestError.new(code: "invalid_grant")
    issued_sessions = RefreshToken.where(user: User.find_by!(email: "native-oauth@example.test")).count
    with_return_url { Auth::CentralOAuthClient.stub(:new, replay) { post native_exchange_path, params: exchange_params(replay_token) } }
    assert_response :unprocessable_entity
    assert_equal "invalid_oauth_grant", response.parsed_body.fetch("code")
    assert_equal issued_sessions, RefreshToken.where(user: User.find_by!(email: "native-oauth@example.test")).count

    closed = User.create!(email: "closed-native@example.test", english_name: "Closed Native", encrypted_password: User.password_hash("Password123!"), metadata: {})
    OAuthIdentity.create!(user: closed, provider: "apple", provider_uid: "closed-native-subject", email: closed.email, credentials: {}, metadata: {})
    closed.close_account!(reason: "self_service")
    closed_central = FakeCentralOAuthClient.new({ "redirect_url" => "https://central.example.test/apple" }, identity_response(provider: "apple", uid: "closed-native-subject", email: closed.email, name: "Closed Native"))
    closed_token = start_transaction(closed_central, provider: "apple")
    with_return_url { Auth::CentralOAuthClient.stub(:new, closed_central) { post native_exchange_path, params: exchange_params(closed_token) } }
    assert_response :unauthorized
    assert_equal "account_closed", response.parsed_body.fetch("code")
  end

  test "resolution/new turns a real account_resolution_required 409 into a working new-account session" do
    central = FakeCentralOAuthClient.new(
      { "redirect_url" => "https://central.example.test/apple" },
      identity_response(provider: "apple", uid: "resolution-new-apple-subject", email: "resolution-new@example.test", name: "Resolution New")
    )
    token = start_transaction(central, provider: "apple")

    with_return_url { Auth::CentralOAuthClient.stub(:new, central) { post native_exchange_path, params: exchange_params(token) } }
    assert_response :conflict
    assert_equal "account_resolution_required", response.parsed_body.fetch("code")
    resolution_token = response.parsed_body.dig("oauth", "resolution_token")
    provider = response.parsed_body.dig("oauth", "provider")
    assert resolution_token.present?
    assert_equal "apple", provider
    assert_nil User.find_by(email: "resolution-new@example.test")

    post native_resolution_new_path, params: {
      oauth: { token: resolution_token, provider: },
      account: { email: "resolution-new@example.test", password: "Password123!", name: "Resolution New", terms_accepted: true }
    }

    assert_response :created
    body = response.parsed_body
    user = User.find_by(email: "resolution-new@example.test")
    assert user.present?
    assert_equal user.id, body.dig("user", "id")
    assert_equal "apple", body.dig("oauth", "provider")
    assert OAuthIdentity.exists?(user:, provider: "apple", provider_uid: "resolution-new-apple-subject")
    assert OAuthAccountResolution.find_by(provider: "apple", provider_uid: "resolution-new-apple-subject").consumed_at.present?

    access_token = body.dig("session", "access_token")
    assert access_token.present?

    get native_profile_path, headers: { "Authorization" => "Bearer #{access_token}" }
    assert_response :success
    assert_equal user.id, response.parsed_body.dig("user", "id")
  end

  test "resolution/existing turns a real account_resolution_required 409 into a working linked session" do
    user = User.create!(email: "resolution-existing@example.test", english_name: "Resolution Existing", encrypted_password: User.password_hash("Password123!"), metadata: {})
    central = FakeCentralOAuthClient.new(
      { "redirect_url" => "https://central.example.test/apple" },
      identity_response(provider: "apple", uid: "resolution-existing-apple-subject", email: "unrelated-apple-email@example.test", name: "Resolution Existing")
    )
    token = start_transaction(central, provider: "apple")

    with_return_url { Auth::CentralOAuthClient.stub(:new, central) { post native_exchange_path, params: exchange_params(token) } }
    assert_response :conflict
    resolution_token = response.parsed_body.dig("oauth", "resolution_token")
    provider = response.parsed_body.dig("oauth", "provider")
    assert_equal "apple", provider
    refute OAuthIdentity.exists?(user:, provider: "apple")

    post native_resolution_existing_path, params: {
      oauth: { token: resolution_token, provider: },
      account: { email: user.email, password: "Password123!" }
    }

    assert_response :success
    body = response.parsed_body
    assert_equal user.id, body.dig("user", "id")
    assert_equal "apple", body.dig("oauth", "provider")
    assert OAuthIdentity.exists?(user:, provider: "apple", provider_uid: "resolution-existing-apple-subject")

    access_token = body.dig("session", "access_token")
    assert access_token.present?

    get native_profile_path, headers: { "Authorization" => "Bearer #{access_token}" }
    assert_response :success
    assert_equal user.id, response.parsed_body.dig("user", "id")
  end

  test "resolution/new for Google turns a real account_resolution_required 409 into a working new-account session" do
    # Regression test for the provider-string mismatch: the resolution record is
    # stored with the identity-form provider ("google_oauth2"), but the client is
    # handed back (and must round-trip) the canonical provider ("google"). Apple's
    # identity-form and canonical strings are identical, so the equivalent Apple
    # test above cannot catch this -- only Google (or Facebook) can.
    central = FakeCentralOAuthClient.new(
      { "redirect_url" => "https://central.example.test/google" },
      identity_response(provider: "google", uid: "resolution-new-google-subject", email: "resolution-new-google@example.test", name: "Resolution New Google")
    )
    token = start_transaction(central, provider: "google")

    with_return_url { Auth::CentralOAuthClient.stub(:new, central) { post native_exchange_path, params: exchange_params(token) } }
    assert_response :conflict
    assert_equal "account_resolution_required", response.parsed_body.fetch("code")
    resolution_token = response.parsed_body.dig("oauth", "resolution_token")
    provider = response.parsed_body.dig("oauth", "provider")
    assert resolution_token.present?
    assert_equal "google", provider
    assert_nil User.find_by(email: "resolution-new-google@example.test")

    # This is the exact request shape the native client is instructed to send:
    # the resolution/new endpoint consumed with the captured canonical provider.
    post native_resolution_new_path, params: {
      oauth: { token: resolution_token, provider: },
      account: { email: "resolution-new-google@example.test", password: "Password123!", name: "Resolution New Google", terms_accepted: true }
    }

    assert_response :created
    body = response.parsed_body
    user = User.find_by(email: "resolution-new-google@example.test")
    assert user.present?
    assert_equal user.id, body.dig("user", "id")
    assert_equal "google", body.dig("oauth", "provider")
    # Storage stays identity-form: the fix must not leak canonical form into OAuthIdentity.
    assert OAuthIdentity.exists?(user:, provider: "google_oauth2", provider_uid: "resolution-new-google-subject")
    refute OAuthIdentity.exists?(user:, provider: "google")
    assert OAuthAccountResolution.find_by(provider: "google_oauth2", provider_uid: "resolution-new-google-subject").consumed_at.present?

    access_token = body.dig("session", "access_token")
    assert access_token.present?

    get native_profile_path, headers: { "Authorization" => "Bearer #{access_token}" }
    assert_response :success
    assert_equal user.id, response.parsed_body.dig("user", "id")
  end

  test "resolution/existing for Google turns a real account_resolution_required 409 into a working linked session" do
    user = User.create!(email: "resolution-existing-google@example.test", english_name: "Resolution Existing Google", encrypted_password: User.password_hash("Password123!"), metadata: {})
    central = FakeCentralOAuthClient.new(
      { "redirect_url" => "https://central.example.test/google" },
      identity_response(provider: "google", uid: "resolution-existing-google-subject", email: "unrelated-google-email@example.test", name: "Resolution Existing Google")
    )
    token = start_transaction(central, provider: "google")

    with_return_url { Auth::CentralOAuthClient.stub(:new, central) { post native_exchange_path, params: exchange_params(token) } }
    assert_response :conflict
    resolution_token = response.parsed_body.dig("oauth", "resolution_token")
    provider = response.parsed_body.dig("oauth", "provider")
    assert_equal "google", provider
    refute OAuthIdentity.exists?(user:, provider: "google_oauth2")

    # Before the fix, consuming with the canonical "google" the API contract
    # actually handed back raised Auth::OAuthAccountResolution::ProviderMismatch
    # because the resolution record was stored as "google_oauth2".
    post native_resolution_existing_path, params: {
      oauth: { token: resolution_token, provider: },
      account: { email: user.email, password: "Password123!" }
    }

    assert_response :success
    body = response.parsed_body
    assert_equal user.id, body.dig("user", "id")
    assert_equal "google", body.dig("oauth", "provider")
    assert OAuthIdentity.exists?(user:, provider: "google_oauth2", provider_uid: "resolution-existing-google-subject")
    refute OAuthIdentity.exists?(user:, provider: "google")

    access_token = body.dig("session", "access_token")
    assert access_token.present?

    get native_profile_path, headers: { "Authorization" => "Bearer #{access_token}" }
    assert_response :success
    assert_equal user.id, response.parsed_body.dig("user", "id")
  end

  test "resolution endpoints reject a wrong password proof, a reused token, and an unregistered token" do
    user = User.create!(email: "resolution-wrong-pw@example.test", english_name: "Resolution Wrong", encrypted_password: User.password_hash("Password123!"), metadata: {})
    central = FakeCentralOAuthClient.new(
      { "redirect_url" => "https://central.example.test/apple" },
      identity_response(provider: "apple", uid: "resolution-wrong-pw-apple-subject", email: "wrong-pw-apple@example.test", name: "Resolution Wrong")
    )
    token = start_transaction(central, provider: "apple")
    with_return_url { Auth::CentralOAuthClient.stub(:new, central) { post native_exchange_path, params: exchange_params(token) } }
    assert_response :conflict
    resolution_token = response.parsed_body.dig("oauth", "resolution_token")
    provider = response.parsed_body.dig("oauth", "provider")

    post native_resolution_existing_path, params: { oauth: { token: resolution_token, provider: }, account: { email: user.email, password: "not-the-password" } }
    assert_response :unauthorized
    assert_equal "existing_account_proof_failed", response.parsed_body.fetch("code")
    refute OAuthIdentity.exists?(user:, provider: "apple")

    get native_resolution_path(token: "not-a-real-token", provider:)
    assert_response :unauthorized
    assert_equal "resolution_invalid", response.parsed_body.fetch("code")

    post native_resolution_existing_path, params: { oauth: { token: resolution_token, provider: }, account: { email: user.email, password: "Password123!" } }
    assert_response :success

    post native_resolution_existing_path, params: { oauth: { token: resolution_token, provider: }, account: { email: user.email, password: "Password123!" } }
    assert_response :unauthorized
    assert_equal "resolution_consumed", response.parsed_body.fetch("code")
  end

  private

  def native_start_path(temple_slug: @temple.slug)
    "/api/v1/account/native/oauth/start?temple_slug=#{temple_slug}"
  end

  def native_exchange_path(temple_slug: @temple.slug)
    "/api/v1/account/native/oauth/exchange?temple_slug=#{temple_slug}"
  end

  def native_resolution_path(temple_slug: @temple.slug, token:, provider:)
    "/api/v1/account/native/oauth/resolution?temple_slug=#{temple_slug}&token=#{token}&provider=#{provider}"
  end

  def native_resolution_existing_path(temple_slug: @temple.slug)
    "/api/v1/account/native/oauth/resolution/existing?temple_slug=#{temple_slug}"
  end

  def native_resolution_new_path(temple_slug: @temple.slug)
    "/api/v1/account/native/oauth/resolution/new?temple_slug=#{temple_slug}"
  end

  def native_profile_path(temple_slug: @temple.slug)
    "/api/v1/account/native/profile?temple_slug=#{temple_slug}"
  end

  def start_params(provider: "google", pkce_method: "S256")
    { oauth: { provider:, pkce_challenge: @challenge, pkce_method: } }
  end

  def exchange_params(transaction_token, verifier: @verifier)
    { oauth: { code: "central-code", transaction_token:, pkce_verifier: verifier }, device: { device_id: "native-1", platform: "ios" } }
  end

  def start_transaction(central, provider: "google")
    with_return_url do
      Auth::CentralOAuthClient.stub(:new, central) { post native_start_path, params: start_params(provider:) }
    end
    assert_response :created
    response.parsed_body.dig("oauth", "transaction_token")
  end

  def identity_response(provider: "google", uid: "google-native-subject", email: "native-oauth@example.test", name: "Native OAuth", token: nil)
    { "provider" => provider, "uid" => uid, "email" => email, "email_verified" => true, "name" => name, "credentials" => { "token" => token || "central-token" } }
  end

  def id_token(sub:, email:)
    payload = Base64.urlsafe_encode64(JSON.generate({ "sub" => sub, "email" => email }), padding: false)
    "header.#{payload}.signature"
  end

  # The central auth tenant is a deployment identity, supplied here the way the
  # return URL is. It used to fall back to the temple's slug, which is what made
  # signing in require a temple; there is no fallback now, so a test that
  # exercises OAuth has to configure the deployment.
  def with_return_url(&block)
    previous = ENV["AUTH_TENANT_SLUG"]
    ENV["AUTH_TENANT_SLUG"] = "shengfukung"
    AppConstants::OAuth.stub(:native_return_url, @return_url, &block)
  ensure
    previous.nil? ? ENV.delete("AUTH_TENANT_SLUG") : ENV["AUTH_TENANT_SLUG"] = previous
  end
end
