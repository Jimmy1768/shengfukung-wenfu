require "test_helper"

class FeatureFlagRolloutTest < ActiveSupport::TestCase
  test "enforces rollout percentage bounds" do
    entry = ConfigEntry.create!(
      key: "seed.feature_flag",
      scope_type: "system",
      value: {}
    )
    rollout = FeatureFlagRollout.new(
      config_entry: entry,
      rollout_percentage: 150,
      enabled_by_default: true
    )
    assert_not rollout.valid?
    assert_includes rollout.errors[:rollout_percentage], "must be less than or equal to 100"
  end
end
