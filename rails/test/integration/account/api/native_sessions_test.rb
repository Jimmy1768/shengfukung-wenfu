# frozen_string_literal: true

require "test_helper"

class NativeAccountSessionsTest < ActionDispatch::IntegrationTest
  def setup
    @temple = create_temple
    @password = "Password123!"
    @user = User.create!(email: "native-#{SecureRandom.hex(3)}@example.com", english_name: "Native User", encrypted_password: User.password_hash(@password))
  end

  # The app's own login path. It verified by re-hashing the input and comparing,
  # which BCrypt's per-call salt makes permanently false -- so this surface would
  # have broken silently if the bcrypt change had only touched the web sessions
  # controllers, as the upstream commit did.
  test "native login accepts a legacy sha256 digest and upgrades it to bcrypt" do
    @user.update_column(:encrypted_password, User.legacy_password_hash(@password))
    assert @user.reload.legacy_password_hash?

    post "/api/v1/account/native/login", params: { temple_slug: @temple.slug, session: { email: @user.email, password: @password }, device: { device_id: "ios-upgrade", platform: "ios" } }
    assert_response :success
    assert @user.reload.bcrypt_password_hash?, "the native login must upgrade a legacy digest too"
  end

  test "native login rejects a wrong password against a bcrypt digest" do
    post "/api/v1/account/native/login", params: { temple_slug: @temple.slug, session: { email: @user.email, password: "wrong" }, device: { device_id: "ios-bad", platform: "ios" } }
    assert_response :unauthorized
  end

  test "login refresh replay and account-only bootstrap contract" do
    post "/api/v1/account/native/login", params: { temple_slug: @temple.slug, session: { email: @user.email, password: @password }, device: { device_id: "ios-1", platform: "ios" } }
    assert_response :success
    session_payload = response.parsed_body.fetch("session")
    assert_equal "Bearer", session_payload.fetch("token_type")
    assert_not response.parsed_body.fetch("user").key?("admin_account")

    get "/api/v1/account/native/bootstrap", params: { temple_slug: @temple.slug }, headers: { "Authorization" => "Bearer #{session_payload.fetch("access_token")}" }
    assert_response :success
    assert_equal @temple.slug, response.parsed_body.dig("temple", "slug")
    assert_not response.parsed_body.key?("payments")

    post "/api/v1/account/native/refresh", params: { temple_slug: @temple.slug, refresh_token: session_payload.fetch("refresh_token") }
    assert_response :success
    replacement = response.parsed_body.dig("session", "refresh_token")

    post "/api/v1/account/native/refresh", params: { temple_slug: @temple.slug, refresh_token: session_payload.fetch("refresh_token") }
    assert_response :unauthorized
    assert_equal "session_replayed", response.parsed_body.fetch("code")

    post "/api/v1/account/native/refresh", params: { temple_slug: @temple.slug, refresh_token: replacement }
    assert_response :unauthorized
  end

  test "tenant is explicit and signed out requests are rejected" do
    get "/api/v1/account/native/profile", params: { temple_slug: @temple.slug }
    assert_response :unauthorized
    assert_equal "session_invalid", response.parsed_body.fetch("code")

    post "/api/v1/account/native/login", params: { temple_slug: "missing", session: { email: @user.email, password: @password } }
    assert_response :not_found
    assert_equal "tenant_not_found", response.parsed_body.fetch("code")
  end

  test "password recovery does not enumerate users and reset revokes prior native sessions" do
    post "/api/v1/account/native/password/recovery", params: { temple_slug: @temple.slug, email: "missing-#{SecureRandom.hex(3)}@example.com" }
    assert_response :accepted
    assert_equal({ "accepted" => true }, response.parsed_body)

    Auth::PasswordMailer.stub(:reset_email, true) do
      post "/api/v1/account/native/password/recovery", params: { temple_slug: @temple.slug, email: @user.email }
    end
    assert_response :accepted
    assert_equal({ "accepted" => true }, response.parsed_body)

    login_payload = native_login
    reset_token = Auth::PasswordReset.request_reset_for(@user)
    post "/api/v1/account/native/password/reset", params: { temple_slug: @temple.slug, token: reset_token, password: "ChangedPassword123!", password_confirmation: "ChangedPassword123!", device: { device_id: "ios-2", platform: "ios" } }
    assert_response :success
    assert response.parsed_body.dig("session", "access_token").present?

    get "/api/v1/account/native/profile", params: { temple_slug: @temple.slug }, headers: bearer(login_payload.fetch("access_token"))
    assert_response :unauthorized
    assert_equal "session_revoked", response.parsed_body.fetch("code")
  end

  test "expired and explicitly revoked native sessions are rejected" do
    session_payload = native_login
    claims = Auth::JwtService.decode(session_payload.fetch("access_token"))

    expired = Auth::JwtService.encode({ "sub" => @user.id, "native_session_id" => claims.fetch("native_session_id"), "scope" => "account" }, expires_in: -(Auth::JwtConfig::LEEWAY + 1))
    get "/api/v1/account/native/profile", params: { temple_slug: @temple.slug }, headers: bearer(expired)
    assert_response :unauthorized
    assert_equal "session_invalid", response.parsed_body.fetch("code")

    ::RefreshToken.find(claims.fetch("native_session_id")).update!(revoked: true)
    get "/api/v1/account/native/profile", params: { temple_slug: @temple.slug }, headers: bearer(session_payload.fetch("access_token"))
    assert_response :unauthorized
    assert_equal "session_revoked", response.parsed_body.fetch("code")
  end

  test "a signed token outside the account scope is rejected" do
    session_payload = native_login
    claims = Auth::JwtService.decode(session_payload.fetch("access_token"))
    wrong_scope = Auth::JwtService.encode({ "sub" => @user.id, "native_session_id" => claims.fetch("native_session_id"), "scope" => "admin" })

    get "/api/v1/account/native/profile", params: { temple_slug: @temple.slug }, headers: bearer(wrong_scope)
    assert_response :unauthorized
    assert_equal "session_invalid", response.parsed_body.fetch("code")
  end

  # Signing in does not require a temple. The app has two gates on purpose, and
  # a signed-in patron with no temple loaded is shown the scanner -- which is
  # also where a patron lands after unloading a temple, not only on first run.
  # Before this, login demanded a temple_slug the patron could only obtain by
  # scanning, and scanning was behind the sign-in gate.
  test "a session is issued with no temple at all" do
    assert_no_difference -> { TempleConnection.count } do
      post "/api/v1/account/native/login", params: { session: { email: @user.email, password: @password }, device: { device_id: "ios-no-temple", platform: "ios" } }
      assert_response :success
    end

    session_payload = response.parsed_body.fetch("session")
    assert_equal "Bearer", session_payload.fetch("token_type")
    assert Auth::JwtService.decode(session_payload.fetch("access_token")), "the token must still be usable"
  end

  test "signup is issued with no temple at all" do
    assert_no_difference -> { TempleConnection.count } do
      post "/api/v1/account/native/signup", params: { signup: { email: "no-temple-#{SecureRandom.hex(3)}@example.com", password: @password, password_confirmation: @password }, device: { device_id: "ios-signup", platform: "ios" } }
      assert_response :created
    end
  end

  # The blank case is the only one that changed. A slug that is supplied is
  # still resolved and still joins, so nothing about the existing flow moves.
  test "a session issued with a temple still joins it" do
    assert_difference -> { TempleConnection.count }, 1 do
      post "/api/v1/account/native/login", params: { temple_slug: @temple.slug, session: { email: @user.email, password: @password }, device: { device_id: "ios-joins", platform: "ios" } }
      assert_response :success
    end

    assert TempleConnection.exists?(user_id: @user.id, temple_id: @temple.id)
  end

  # Tolerating a blank slug must not tolerate a wrong one: this is the signal
  # the app's scanner relies on to reject a code naming a temple that does not
  # exist, and it is what keeps the QR's claim from ever winning on its own.
  test "a slug that names nothing is still refused on a session route" do
    post "/api/v1/account/native/login", params: { temple_slug: "no-such-temple", session: { email: @user.email, password: @password }, device: { device_id: "ios-bad-temple", platform: "ios" } }
    assert_response :not_found
    assert_equal "tenant_not_found", response.parsed_body.fetch("code")
  end

  # OAuth sign-in is sign-in. A patron with no temple loaded reaches these from
  # the same signed-out screen as the password path, so they carry no slug
  # either; leaving them temple-required would have broken Google and Apple
  # sign-in for exactly the patron this change exists to serve.
  test "oauth start works with no temple, and still refuses an unknown one" do
    post "/api/v1/account/native/oauth/start", params: { oauth: { provider: "google", pkce_challenge: "a" * 43, pkce_method: "S256" } }
    # It gets past temple resolution and fails later, on provider configuration
    # that this environment does not have -- which is the point: the request is
    # no longer rejected for having no tenant. Asserting the absence of the two
    # tenant codes states that directly, without pinning the provider outcome.
    refute_equal "tenant_required", response.parsed_body["code"], "a missing temple must not be refused"
    refute_equal "tenant_not_found", response.parsed_body["code"]
    assert_equal "native_oauth_unavailable", response.parsed_body["code"],
      "it should reach the provider stage; if this changes, the reason it got there is what matters"

    post "/api/v1/account/native/oauth/start", params: { temple_slug: "no-such-temple", oauth: { provider: "google", pkce_challenge: "a" * 43, pkce_method: "S256" } }
    assert_response :not_found
    assert_equal "tenant_not_found", response.parsed_body.fetch("code")
  end

  # The relaxation is scoped to the routes that issue a session. Everything
  # authenticated still demands a temple, because it operates inside one.
  test "an authenticated route still requires a temple" do
    session_payload = native_login

    get "/api/v1/account/native/bootstrap", headers: bearer(session_payload.fetch("access_token"))
    assert_response :unprocessable_entity
    assert_equal "tenant_required", response.parsed_body.fetch("code")
  end

  private

  def native_login
    post "/api/v1/account/native/login", params: { temple_slug: @temple.slug, session: { email: @user.email, password: @password }, device: { device_id: "ios-1", platform: "ios" } }
    assert_response :success
    response.parsed_body.fetch("session")
  end

  def bearer(access_token)
    { "Authorization" => "Bearer #{access_token}" }
  end
end
