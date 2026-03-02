# frozen_string_literal: true

require "test_helper"
require "zlib"

module Account
  class RequestThrottlingTest < ActionDispatch::IntegrationTest
    test "blacklisted html form submission redirects back with alert" do
      ip = "203.0.113.5"
      BlacklistEntry.create!(
        scope_type: "IpAddress",
        scope_id: Zlib.crc32(ip),
        reason: "test_blacklist",
        active: true,
        expires_at: 1.hour.from_now
      )

      post account_login_path,
        params: { email: "blocked@example.com", password: "wrong" },
        headers: { "REMOTE_ADDR" => ip, "HTTP_REFERER" => account_login_path }

      assert_redirected_to account_login_path
      assert_equal "Too many requests. Please try again shortly.", flash[:alert]
    end
  end
end
