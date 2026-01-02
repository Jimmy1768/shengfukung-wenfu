require "test_helper"

class NotificationsDispatchEventTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "dispatch-event@test.local",
      english_name: "Dispatch Event User",
      encrypted_password: User.password_hash("DispatchSecret!1")
    )
    @rule = NotificationRule.create!(
      event_key: "notify.event",
      channel: "push"
    )
  end

  test "records push deliveries" do
    Notifications::Push::Delivery.stub(:call, true) do
      Notifications::Email::Delivery.stub(:call, true) do
        result = Notifications::DispatchEvent.new(user: @user, event_key: "notify.event").call
        assert_equal true, result[:push]
        assert_nil result[:email]

        last_push = Notification.where(channel: "push").order(:created_at).last
        assert_equal "sent", last_push.status
        assert_equal @rule, last_push.notification_rule
      end
    end
  end

  test "falls back to email when push fails" do
    Notifications::Push::Delivery.stub(:call, ->(**) { false }) do
      Notifications::Email::Delivery.stub(:call, ->(**) { true }) do
        result = Notifications::DispatchEvent.new(user: @user, event_key: "notify.event").call
        assert_equal true, result[:email]

        push_record = Notification.where(channel: "push").order(:created_at).last
        email_record = Notification.where(channel: "email").order(:created_at).last
        assert_equal "failed", push_record.status
        assert_equal "sent", email_record.status
      end
    end
  end
end
