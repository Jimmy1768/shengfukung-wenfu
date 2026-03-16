# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class PaymentWebhooksTest < ActionDispatch::IntegrationTest
      test "fake webhook marks payment completed and registration paid" do
        temple = create_temple(slug: "webhook-temple")
        offering = create_offering(temple:, slug: "webhook-offering", price_cents: 1000)
        user = User.create!(
          email: "webhook-user@example.com",
          english_name: "Webhook User",
          encrypted_password: User.password_hash("Password123!")
        )
        registration = create_registration(user:, offering:)
        payment = create_payment(
          registration: registration,
          status: TemplePayment::STATUSES[:pending],
          method: TemplePayment::PAYMENT_METHODS[:line_pay],
          provider: "fake",
          provider_reference: "fake_ref_abc",
          processed_at: nil
        )

        post api_v1_payment_webhook_path(provider: "fake"),
          params: {
            event_type: "payment.updated",
            event_id: "evt_abc_1",
            provider_reference: payment.provider_reference,
            status: "completed",
            temple_slug: temple.slug
          }.to_json,
          headers: { "CONTENT_TYPE" => "application/json" }

        assert_response :success
        assert_equal TemplePayment::STATUSES[:completed], payment.reload.status
        assert_equal TempleRegistration::PAYMENT_STATUSES[:paid], registration.reload.payment_status
        assert SystemAuditLog.exists?(action: "system.payments.webhook_applied", target: payment)
        assert SystemAuditLog.exists?(action: "system.registrations.payment_status_updated", target: registration)
      end

      test "duplicate webhook event is ignored" do
        temple = create_temple(slug: "webhook-dup")
        create_offering(temple:, slug: "webhook-dup-offering", price_cents: 1000)
        PaymentWebhookLog.create!(
          temple: temple,
          provider: "fake",
          event_type: "payment.updated",
          provider_reference: "fake_ref_dup",
          provider_event_id: "evt_dup_1",
          payload: {},
          signature_valid: true,
          processed: true,
          received_at: Time.current,
          processed_at: Time.current
        )

        post api_v1_payment_webhook_path(provider: "fake"),
          params: {
            event_type: "payment.updated",
            event_id: "evt_dup_1",
            provider_reference: "fake_ref_dup",
            status: "completed",
            temple_slug: temple.slug
          }.to_json,
          headers: { "CONTENT_TYPE" => "application/json" }

        assert_response :success
        body = JSON.parse(response.body)
        assert_equal true, body["duplicate"]
      end
    end
  end
end
