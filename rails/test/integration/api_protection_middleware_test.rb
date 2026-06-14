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

  test "continues api request when audit recording fails" do
    mock_client = Object.new
    deliveries = []

    mock_client.define_singleton_method(:send_email) do |**kwargs|
      deliveries << kwargs
      true
    end

    Notifications::BrevoClient.stub(:new, mock_client) do
      ApiProtection::RequestAudit.stub(:call, ->(request:) { raise StandardError, "audit offline" }) do
        post "/api/v1/demo_contacts", params: {
          email: "audit-offline@test.local",
          name: "Audit Offline User",
          locale: "en",
          message: "Testing audit failure isolation"
        }
      end
    end

    assert_response :created
    assert_equal 2, deliveries.length
    assert_not ApiUsageLog.exists?(request_path: "/api/v1/demo_contacts")
  end

  test "does not rescue and replay downstream application exceptions" do
    calls = 0
    app = lambda do |_env|
      calls += 1
      raise "downstream failure"
    end
    middleware = ApiProtection::AuditMiddleware.new(app)
    env = Rack::MockRequest.env_for("/api/v1/demo_contacts", method: "POST")

    ApiProtection::RequestAudit.stub(:call, nil) do
      assert_raises(RuntimeError) { middleware.call(env) }
    end

    assert_equal 1, calls
  end
end
