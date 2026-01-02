require "test_helper"

class NotificationRuleTest < ActiveSupport::TestCase
  test "requires event_key and channel" do
    rule = NotificationRule.new
    assert_not rule.valid?
    assert_includes rule.errors[:event_key], "can't be blank"
    assert_includes rule.errors[:channel], "can't be blank"
  end

  test "enforces known channels" do
    rule = NotificationRule.new(event_key: "test", channel: "fax")
    assert_not rule.valid?
    assert_includes rule.errors[:channel], "is not included in the list"
  end
end
