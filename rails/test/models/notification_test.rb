require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  test "requires channel and status" do
    notification = Notification.new
    notification.status = nil
    notification.validate
    assert notification.errors.added?(:channel, :blank)
    assert notification.errors.added?(:status, :blank)
  end

  test "enforces known statuses" do
    notification = Notification.new(channel: "email", status: "unknown")
    assert_not notification.valid?
    assert_includes notification.errors[:status], "is not included in the list"
  end
end
