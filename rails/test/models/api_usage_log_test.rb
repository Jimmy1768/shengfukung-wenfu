require "test_helper"

class ApiUsageLogTest < ActiveSupport::TestCase
  test "requires request details" do
    log = ApiUsageLog.new
    log.validate
    assert log.errors.added?(:request_path, :blank), "request_path should be required"
    assert log.errors.added?(:occurred_at, :blank), "occurred_at should be required"
  end

  test "can record a successful request" do
    log = ApiUsageLog.create!(
      request_path: "/api/test",
      http_method: "GET",
      occurred_at: Time.current
    )
    assert_equal "/api/test", log.request_path
  end
end
