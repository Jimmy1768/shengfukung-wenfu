require "test_helper"

class DataAnomalyTest < ActiveSupport::TestCase
  test "validates required attributes" do
    anomaly = DataAnomaly.new
    anomaly.severity = nil
    anomaly.status = nil
    anomaly.validate
    assert anomaly.errors.added?(:detector_key, :blank)
    assert anomaly.errors.added?(:severity, :blank)
    assert anomaly.errors.added?(:detected_at, :blank)
    assert anomaly.errors.added?(:status, :blank)
  end

  test "restricts to known statuses" do
    anomaly = DataAnomaly.new(
      detector_key: "test",
      severity: "critical",
      status: "unknown",
      detected_at: Time.current
    )
    assert_not anomaly.valid?
    assert_includes anomaly.errors[:status], "is not included in the list"
  end
end
