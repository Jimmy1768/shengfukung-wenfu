require "test_helper"

class ConfigEntryTest < ActiveSupport::TestCase
  test "requires key and scope" do
    entry = ConfigEntry.new(scope_type: nil)
    entry.validate
    assert entry.errors.added?(:key, :blank)
    assert entry.errors.added?(:scope_type, :blank)
  end

  test "associates with feature flag rollouts" do
    entry = ConfigEntry.create!(
      key: "seed.config_entry",
      scope_type: "system",
      value: { "enabled" => true }
    )
    rollout = entry.create_feature_flag_rollout!(
      rollout_percentage: 60,
      enabled_by_default: true
    )
    assert_equal rollout, entry.feature_flag_rollout
    assert_equal 60, rollout.rollout_percentage
  end
end
