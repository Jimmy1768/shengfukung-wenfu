# frozen_string_literal: true

require "test_helper"

class ApiProtectionSpikeAlertCheckerTest < ActiveSupport::TestCase
  class FakeAlertSender
    class << self
      attr_accessor :calls
    end

    self.calls = []

    def self.call(**kwargs)
      self.calls << kwargs
      true
    end
  end

  setup do
    ApiUsageLog.delete_all
    FakeAlertSender.calls = []
  end

  test "does not trigger when thresholds are not met" do
    create_decision_log("throttle", scope_id: "1")

    result = ApiProtection::SpikeAlertChecker.new(
      window_minutes: 15,
      min_events: 5,
      min_unique_scopes: 2,
      alert_sender: FakeAlertSender
    ).call

    assert_not result.triggered?
    assert_equal 0, FakeAlertSender.calls.length
  end

  test "triggers and sends alert when thresholds are exceeded" do
    5.times do |index|
      create_decision_log("throttle", scope_id: index.to_s, path: "/api/v1/demo_contacts")
    end

    result = ApiProtection::SpikeAlertChecker.new(
      window_minutes: 15,
      min_events: 4,
      min_unique_scopes: 4,
      alert_sender: FakeAlertSender
    ).call

    assert result.triggered?
    assert_equal 1, FakeAlertSender.calls.length
    assert_equal "api_protection.abuse_spike", FakeAlertSender.calls.first[:alert_key]
  end

  test "dry run does not send even when thresholds are exceeded" do
    5.times do |index|
      create_decision_log("blacklist_deny", scope_id: index.to_s, path: "/api/v1/payments/webhooks/ecpay")
    end

    result = ApiProtection::SpikeAlertChecker.new(
      window_minutes: 15,
      min_events: 4,
      min_unique_scopes: 4,
      alert_sender: FakeAlertSender
    ).call(dry_run: true)

    assert result.triggered?
    assert_equal 0, FakeAlertSender.calls.length
  end

  private

  def create_decision_log(decision, scope_id:, path: "/api/v1/demo_contacts")
    ApiUsageLog.create!(
      request_path: path,
      http_method: "POST",
      occurred_at: Time.current,
      ip_address: "127.0.0.1",
      metadata: {
        "decision" => decision,
        "scope_type" => "IpAddress",
        "scope_id" => scope_id
      }
    )
  end
end
