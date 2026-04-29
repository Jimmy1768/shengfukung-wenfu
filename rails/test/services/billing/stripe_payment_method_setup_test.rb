# frozen_string_literal: true

require "test_helper"

class Billing::StripePaymentMethodSetupTest < ActiveSupport::TestCase
  FakeSession = Struct.new(:id, :url, :setup_intent, :customer, keyword_init: true) do
    def to_hash
      {
        "id" => id,
        "url" => url,
        "setup_intent" => setup_intent.respond_to?(:id) ? setup_intent.id : setup_intent,
        "customer" => customer.respond_to?(:id) ? customer.id : customer
      }.compact
    end
  end

  FakeSetupIntent = Struct.new(:id, :payment_method, keyword_init: true)
  FakePaymentMethod = Struct.new(:id, :card, keyword_init: true)
  FakeCard = Struct.new(:brand, :last4, :exp_month, :exp_year, keyword_init: true)
  FakeCustomer = Struct.new(:id, keyword_init: true)

  test "start creates a Stripe setup checkout session" do
    temple = create_temple(slug: "stripe-temple")
    admin = create_admin_user(temple: temple, role: "owner")
    captured_args = nil
    fake_session = FakeSession.new(id: "cs_setup_123", url: "https://checkout.stripe.com/c/cs_setup_123")

    with_stripe_secret do
      Stripe::Checkout::Session.stub(:create, ->(args) { captured_args = args; fake_session }) do
        result = Billing::StripePaymentMethodSetup.start(
          temple: temple,
          admin: admin,
          success_url: "https://example.test/admin/payment_methods/billing_setup_return",
          cancel_url: "https://example.test/admin/payment_methods"
        )

        assert_equal "cs_setup_123", result.session_id
        assert_equal fake_session.url, result.url
      end
    end

    assert_equal "setup", captured_args[:mode]
    assert_equal admin.email, captured_args[:customer_email]
    assert_includes captured_args[:success_url], "checkout_session_id={CHECKOUT_SESSION_ID}"
    assert_equal "stripe-temple", captured_args[:metadata][:temple_slug]
  end

  test "complete saves Stripe billing method details on temple" do
    temple = create_temple
    admin = create_admin_user(temple: temple, role: "owner")
    card = FakeCard.new(brand: "visa", last4: "4242", exp_month: 12, exp_year: 2030)
    payment_method = FakePaymentMethod.new(id: "pm_123", card: card)
    setup_intent = FakeSetupIntent.new(id: "seti_123", payment_method: payment_method)
    fake_session = FakeSession.new(
      id: "cs_setup_123",
      setup_intent: setup_intent,
      customer: FakeCustomer.new(id: "cus_123")
    )

    with_stripe_secret do
      Stripe::Checkout::Session.stub(:retrieve, ->(_args) { fake_session }) do
        Billing::StripePaymentMethodSetup.complete(
          temple: temple,
          admin: admin,
          checkout_session_id: "cs_setup_123"
        )
      end
    end

    billing = temple.reload.billing_settings
    assert temple.billing_payment_method_on_file?
    assert_equal "stripe", billing["provider"]
    assert_equal "cus_123", billing["stripe_customer_id"]
    assert_equal "pm_123", billing["stripe_payment_method_id"]
    assert_equal "seti_123", billing["stripe_setup_intent_id"]
    assert_equal "visa", billing["card_brand"]
    assert_equal "4242", billing["card_last4"]
    assert_nil billing["grace_started_at"]
  end

  private

  def with_stripe_secret
    original_secret = Rails.configuration.x.stripe.secret_key
    Rails.configuration.x.stripe.secret_key = "sk_test_123"
    yield
  ensure
    Rails.configuration.x.stripe.secret_key = original_secret
  end
end
