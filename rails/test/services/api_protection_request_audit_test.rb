require "test_helper"
require "ostruct"
require "zlib"

class ApiProtectionRequestAuditTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "audit@test.local",
      english_name: "Audit User",
      encrypted_password: User.password_hash("AuditSecret!1")
    )
  end

  test "logs usage and counters for tracked routes" do
    env = Rack::MockRequest.env_for("/api/v1/demo_contacts", method: "POST", "REMOTE_ADDR" => "127.0.0.1")
    env["warden"] = OpenStruct.new(user: @user)
    request = ActionDispatch::Request.new(env)

    result = ApiProtection::RequestAudit.call(request: request)
    assert_not result.blocked?
    assert_equal "api.account.write", result.endpoint_class
    assert ApiUsageLog.exists?(request_path: "/api/v1/demo_contacts")
    assert ApiRequestCounter.where(scope_type: %w[User IpAddress]).exists?
  end

  test "blocks when IP is blacklisted" do
    ip = "192.0.2.1"
    BlacklistEntry.create!(
      scope_type: "IpAddress",
      scope_id: Zlib.crc32(ip),
      reason: "seed",
      active: true,
      expires_at: 1.hour.from_now
    )

    env = Rack::MockRequest.env_for("/api/v1/demo_contacts", method: "GET", "REMOTE_ADDR" => ip)
    request = ActionDispatch::Request.new(env)
    result = ApiProtection::RequestAudit.call(request: request)
    assert result.blocked?
    assert_equal "blacklist_deny", result.decision
  end

  test "skips non-API paths" do
    request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/marketing", method: "GET"))
    assert_nil ApiProtection::RequestAudit.call(request: request)
  end

  test "classifies account html write routes for controller guard usage" do
    request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/account/login", method: "POST"))
    result = ApiProtection::RequestAudit.call(request: request)

    assert_not result.blocked?
    assert_equal "web.account.form_submit", result.endpoint_class
  end
end
