require "test_helper"

class BlacklistEntryTest < ActiveSupport::TestCase
  test "requires a reason" do
    entry = BlacklistEntry.new(scope_type: "IpAddress", scope_id: 123)
    assert_not entry.valid?
    assert_includes entry.errors[:reason], "can't be blank"
  end

  test "can be activated" do
    entry = BlacklistEntry.create!(
      scope_type: "IpAddress",
      scope_id: 123,
      reason: "seed",
      active: true
    )
    assert entry.active
  end
end
