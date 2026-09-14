# frozen_string_literal: true

require "test_helper"

class Account::ConnectQrTest < ActionDispatch::IntegrationTest
  setup do
    @temple = create_temple
    @user = User.create!(
      email: "connect-qr@example.com", english_name: "Connect QR",
      encrypted_password: User.password_hash("Password123!")
    )
  end

  test "the page renders a QR the app will accept" do
    sign_in_account(@user, temple_slug: @temple.slug)

    get account_connect_path
    assert_response :success
    assert_includes response.body, "<svg"

    # The exact contract in mobile/app/tenant/binding.js.
    url = URI.parse(Templemate::ConnectionLink.for(temple: @temple))
    assert_equal "https", url.scheme
    assert_equal URI.parse(Templemate::ConnectionLink::ORIGIN).host, url.host
    assert_equal "#{Templemate::ConnectionLink::PATH_PREFIX}/#{@temple.slug}", url.path
    assert_nil url.fragment
    assert_nil url.userinfo
    assert_nil url.query
  end

  test "it requires a signed-in patron" do
    get account_connect_path
    assert_response :redirect
    refute_includes response.body.to_s, "<svg"
  end

  # The code names the temple, which is the whole point: one app, built with no
  # tenant in it, loads whichever temple the scanned code identifies.
  test "the link carries this temple's own slug" do
    other = create_temple(slug: "second-temple", name: "Second Temple")

    assert_equal "#{Templemate::ConnectionLink::ORIGIN}#{Templemate::ConnectionLink::PATH_PREFIX}/#{@temple.slug}",
      Templemate::ConnectionLink.for(temple: @temple)
    assert_equal "#{Templemate::ConnectionLink::ORIGIN}#{Templemate::ConnectionLink::PATH_PREFIX}/#{other.slug}",
      Templemate::ConnectionLink.for(temple: other)
    refute_equal Templemate::ConnectionLink.for(temple: @temple), Templemate::ConnectionLink.for(temple: other)
  end

  # The origin used to be derived from request.base_url, and nginx serves
  # www.<domain> directly rather than redirecting -- so a code generated on www
  # encoded a host the app's exact-origin check rejected, with no visible
  # reason. That is how it failed for the Director's staff on 2026-09-02.
  #
  # The origin is now a fixed platform constant, so the request host cannot
  # reach it at all. This asserts the stronger property the fix actually bought:
  # not "www is stripped" but "the request cannot influence the origin".
  test "the encoded link ignores the request host entirely" do
    sign_in_account(@user, temple_slug: @temple.slug)
    get account_connect_path
    assert_response :success

    # Rails' integration host is www.example.com.
    assert_equal "www.example.com", URI.parse(@request.base_url).host

    link = Templemate::ConnectionLink.for(temple: @temple)
    assert link.start_with?(Templemate::ConnectionLink::ORIGIN), "the platform origin must be used verbatim"
    refute_includes link, "example.com"
    refute_includes link, "www."

    # The page shows the encoded link, so a failed scan is diagnosable.
    assert_includes response.body, link
    assert_includes response.body, "<svg"
  end
end
