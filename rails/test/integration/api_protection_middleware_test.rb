require "test_helper"

class ApiProtectionMiddlewareTest < ActionDispatch::IntegrationTest
  test "logs api requests and increments counters" do
    mock_client = Object.new
    def mock_client.send_email(**)
      true
    end

    Notifications::BrevoClient.stub(:new, mock_client) do
      post "/api/v1/demo_contacts", params: {
        email: "integration@test.local",
        name: "Integration User",
        locale: "en",
        message: "Testing middleware"
      }
    end

    assert_response :created
    assert ApiUsageLog.exists?(request_path: "/api/v1/demo_contacts")
    counter = ApiRequestCounter.order(:created_at).last
    assert_operator counter.count, :>=, 1
  end
end
