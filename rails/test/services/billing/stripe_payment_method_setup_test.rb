# frozen_string_literal: true

require "test_helper"

class Billing::StripePaymentMethodSetupTest < ActiveSupport::TestCase
  FakeSession = Struct.new(:id, :url, :subscription, :customer, keyword_init: true) do
    def to_hash
      {
        "id" => id,
        "url" => url,
        "subscription" => subscription.respond_to?(:id) ? subscription.id : subscription,
        "customer" => customer.respond_to?(:id) ? customer.id : customer
      }.compact
    end
  end

  FakePaymentMethod = Struct.new(:id, :card, keyword_init: true)
  FakeCard = Struct.new(:brand, :last4, :exp_month, :exp_year, keyword_init: true)
  FakeCustomer = Struct.new(:id, :invoice_settings, keyword_init: true)
  FakeSubscription = Struct.new(:id, :default_payment_method, keyword_init: true)

  test "start creates a Stripe subscription checkout session" do
    temple = create_temple(slug: "stripe-temple")
    admin = create_admin_user(temple: temple, role: "owner")
    captured_args = nil
    fake_session = FakeSession.new(id: "cs_setup_123", url: "https://checkout.stripe.com/c/cs_setup_123")

    with_stripe_secret do
      without_stripe_price_id do
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
    end

    assert_equal "subscription", captured_args[:mode]
    assert_equal admin.email, captured_args[:customer_email]
    assert_includes captured_args[:success_url], "checkout_session_id={CHECKOUT_SESSION_ID}"
    assert_equal "stripe-temple", captured_args[:metadata][:temple_slug]
    assert_equal 3_600_000, captured_args[:line_items].first.dig(:price_data, :unit_amount)
    assert_equal "year", captured_args[:line_items].first.dig(:price_data, :recurring, :interval)
  end

  test "complete saves Stripe billing method details on temple" do
    temple = create_temple
    admin = create_admin_user(temple: temple, role: "owner")
    card = FakeCard.new(brand: "visa", last4: "4242", exp_month: 12, exp_year: 2030)
    payment_method = FakePaymentMethod.new(id: "pm_123", card: card)
    subscription = FakeSubscription.new(id: "sub_123", default_payment_method: payment_method)
    fake_session = FakeSession.new(
      id: "cs_setup_123",
      subscription: subscription,
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
    assert_equal "sub_123", billing["stripe_subscription_id"]
    assert_equal "pm_123", billing["stripe_payment_method_id"]
    assert_equal "visa", billing["card_brand"]
    assert_equal "4242", billing["card_last4"]
    assert_equal 300_000, billing["monthly_fee_cents"]
    assert_equal 3_600_000, billing["annual_fee_cents"]
    assert_equal "year", billing["billing_interval"]
    assert_equal 12, billing["billing_interval_months"]
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

  def without_stripe_price_id
    original_price_id = ENV.delete("STRIPE_TEMPLEMATE_PLATFORM_PRICE_ID")
    yield
  ensure
    ENV["STRIPE_TEMPLEMATE_PLATFORM_PRICE_ID"] = original_price_id if original_price_id.present?
  end
end
