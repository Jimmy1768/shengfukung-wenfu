# frozen_string_literal: true

require "test_helper"

module Registrations
  class ExpiryNotificationDispatcherTest < ActiveSupport::TestCase
    FakeBrevoClient = Struct.new(:calls) do
      def send_email(**kwargs)
        calls << kwargs
        true
      end
    end

    test "expiring soon notifies patron and temple admins" do
      temple = create_temple
      patron = User.create!(
        email: "patron-#{SecureRandom.hex(3)}@example.com",
        encrypted_password: User.password_hash("Password123!"),
        english_name: "Patron User"
      )
      admin_user = create_admin_user(temple:, role: "owner")
      offering = create_offering(temple:)
      registration = create_registration(
        user: patron,
        offering: offering,
        payment_status: TempleRegistration::PAYMENT_STATUSES[:pending],
        fulfillment_status: TempleRegistration::FULFILLMENT_STATUSES[:open],
        expires_at: 12.hours.from_now
      )
      fake_client = FakeBrevoClient.new([])

      Notifications::BrevoClient.stub(:new, fake_client) do
        ExpiryNotificationDispatcher.dispatch_expiring_soon!(now: Time.current)
      end

      assert_equal 2, fake_client.calls.size
      recipients = fake_client.calls.map { |call| call.dig(:to, :email) }
      assert_includes recipients, patron.email
      assert_includes recipients, admin_user.email
      assert registration.reload.metadata.dig("expiry_notifications", ExpiryNotificationDispatcher::EXPIRING_SOON_EVENT).present?
      assert_equal 2, Notification.where(message_key: ExpiryNotificationDispatcher::EXPIRING_SOON_EVENT, status: "sent").count
    end

    test "expired notifies recipients and respects email opt-out preference" do
      temple = create_temple
      patron = User.create!(
        email: "patron-#{SecureRandom.hex(3)}@example.com",
        encrypted_password: User.password_hash("Password123!"),
        english_name: "Patron User"
      )
      admin_user = create_admin_user(temple:, role: "owner")
      NotificationPreference.create!(user: patron, channel: "email", enabled: false)
      offering = create_offering(temple:)
      registration = create_registration(
        user: patron,
        offering: offering,
        payment_status: TempleRegistration::PAYMENT_STATUSES[:pending],
        fulfillment_status: TempleRegistration::FULFILLMENT_STATUSES[:cancelled],
        cancelled_at: 30.minutes.ago,
        expires_at: nil
      )
      fake_client = FakeBrevoClient.new([])

      Notifications::BrevoClient.stub(:new, fake_client) do
        ExpiryNotificationDispatcher.dispatch_expired!(now: Time.current)
      end

      assert_equal 1, fake_client.calls.size
      recipients = fake_client.calls.map { |call| call.dig(:to, :email) }
      refute_includes recipients, patron.email
      assert_includes recipients, admin_user.email
      assert registration.reload.metadata.dig("expiry_notifications", ExpiryNotificationDispatcher::EXPIRED_EVENT).present?
    end
  end
end
