# frozen_string_literal: true

require "test_helper"

class ApiProtectionRequestClassifierTest < ActiveSupport::TestCase
  test "classifies contact temple html form with dedicated class" do
    request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/account/contact_temple_requests", method: "POST"))
    assert_equal "web.account.form_submit.contact_temple", ApiProtection::RequestClassifier.classify(request)
  end

  test "classifies account auth writes as web.account.form_submit" do
    request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/account/login", method: "POST"))
    assert_equal "web.account.form_submit", ApiProtection::RequestClassifier.classify(request)
  end

  test "classifies admin auth writes as web.admin.form_submit" do
    request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/admin/login", method: "POST"))
    assert_equal "web.admin.form_submit", ApiProtection::RequestClassifier.classify(request)
  end

  test "classifies api webhook ingest with dedicated class" do
    request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/api/v1/payments/webhooks/ecpay", method: "POST"))
    assert_equal "api.webhook.ingest", ApiProtection::RequestClassifier.classify(request)
  end

  test "classifies api contact temple write as api.account.write" do
    request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/api/v1/temples/demo/contact_temple_requests", method: "POST"))
    assert_equal "api.account.write", ApiProtection::RequestClassifier.classify(request)
  end
end
