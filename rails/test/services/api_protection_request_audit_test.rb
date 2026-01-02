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

    assert_nil ApiProtection::RequestAudit.call(request: request)
    assert ApiUsageLog.exists?(request_path: "/api/v1/demo_contacts")
    assert ApiRequestCounter.exists?(scope_type: "IpAddress")
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
    response = ApiProtection::RequestAudit.call(request: request)

    assert response.is_a?(Array)
    assert_equal 429, response[0]
  end

  test "skips non-API paths" do
    request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/marketing", method: "GET"))
    assert_nil ApiProtection::RequestAudit.call(request: request)
  end
end
