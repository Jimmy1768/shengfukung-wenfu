require "test_helper"

class RegistrationPaymentFlowTest < ActionDispatch::IntegrationTest
  FakeRedirectAdapter = Struct.new(:redirect_url) do
    def checkout(**)
      {
        status: "pending",
        provider_checkout_id: "stubbed_chk",
        provider_payment_id: "stubbed_pay",
        provider_reference: "stubbed_ref",
        redirect_url: redirect_url,
        raw: {}
      }
    end
  end

  FakeReturnAdapter = Struct.new(:status) do
    def confirm(**kwargs)
      {
        status: status,
        provider_reference: kwargs[:provider_payment_ref],
        raw: {}
      }
    end
  end

  test "successful registration redirects to payment page" do
    temple = create_temple
    offering = TempleOffering.create!(
      temple:,
      slug: "lantern-festival",
      title: "Lantern Festival",
      currency: "TWD",
      price_cents: 600,
      starts_on: Date.current,
      ends_on: Date.current + 1.day
    )
    user = User.create!(
      email: "flow@example.com",
      english_name: "Flow Member",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    post account_registrations_path, params: {
      offering: offering.slug,
      account_action: "event",
      account_registration_intake_form: {
        contact_name: "Flow Member",
        quantity: 1
      }
    }

    registration = TempleEventRegistration.order(:created_at).last
    assert_redirected_to payment_account_registration_path(registration)

    follow_redirect!
    assert_response :success
    assert_includes response.body, "前往付款"
    assert_includes response.body, offering.title
    assert_includes response.body, api_v1_account_payment_status_path(reference: registration.reference_code)
  end

  test "free registration payment page shows confirmation" do
    temple = create_temple
    offering = TempleOffering.create!(
      temple:,
      slug: "community-potluck",
      title: "Community Potluck",
      currency: "TWD",
      price_cents: 0,
      starts_on: Date.current,
      ends_on: Date.current + 1.day
    )
    user = User.create!(
      email: "free@example.com",
      english_name: "Free Member",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    post account_registrations_path, params: {
      offering: offering.slug,
      account_action: "event",
      account_registration_intake_form: {
        contact_name: "Free Member",
        quantity: 1
      }
    }

    registration = TempleEventRegistration.order(:created_at).last
    assert_redirected_to payment_account_registration_path(registration)

    follow_redirect!
    assert_response :success
    assert_includes response.body, "此報名不需付費，已完成。"
  end

  test "start checkout creates pending payment and stays on payment page" do
    temple = create_temple
    offering = create_offering(temple:, slug: "fake-checkout", title: "Fake Checkout Offering", price_cents: 800)
    user = User.create!(
      email: "fakecheckout@example.com",
      english_name: "Fake Checkout",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)
    registration = create_registration(user:, offering:)

    post start_checkout_account_registration_path(registration)

    assert_redirected_to payment_account_registration_path(registration)
    payment = registration.temple_payments.order(:created_at).last
    assert_not_nil payment
    assert_equal "fake", payment.provider
    assert_equal TemplePayment::STATUSES[:pending], payment.status
    assert_equal TempleRegistration::PAYMENT_STATUSES[:pending], registration.reload.payment_status
  end

  test "start checkout redirects to provider url when adapter returns one" do
    temple = create_temple
    offering = create_offering(temple:, slug: "redirect-checkout", title: "Redirect Checkout Offering", price_cents: 1200)
    user = User.create!(
      email: "redirectcheckout@example.com",
      english_name: "Redirect Checkout",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)
    registration = create_registration(user:, offering:)

    Payments::ProviderResolver.stub(:current_provider, "line_pay") do
      PaymentGateway::LinePayAdapter.stub(:new, FakeRedirectAdapter.new("https://pay.example.test/checkout")) do
        post start_checkout_account_registration_path(registration)
      end
    end

    assert_redirected_to "https://pay.example.test/checkout"
  end

  test "checkout return confirms a line pay payment and redirects back to payment page" do
    temple = create_temple
    offering = create_offering(temple:, slug: "line-return", title: "Line Return", price_cents: 1500)
    user = User.create!(
      email: "linereturn@example.com",
      english_name: "Line Return",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)
    registration = create_registration(user:, offering:)
    create_payment(
      registration: registration,
      amount_cents: registration.total_price_cents,
      status: TemplePayment::STATUSES[:pending],
      method: TemplePayment::PAYMENT_METHODS[:line_pay],
      provider: "line_pay",
      provider_reference: "order_123",
      processed_at: nil
    )

    PaymentGateway::LinePayAdapter.stub(:new, FakeReturnAdapter.new("completed")) do
      get checkout_return_account_registration_path(registration, provider: "line_pay", transactionId: "tx_123", orderId: "order_123")
    end

    assert_redirected_to payment_account_registration_path(registration)
    follow_redirect!
    assert_includes response.body, "已完成付款。"
    assert_equal TempleRegistration::PAYMENT_STATUSES[:paid], registration.reload.payment_status
    assert_equal TemplePayment::STATUSES[:completed], registration.temple_payments.order(:created_at).last.reload.status
  end

  test "repeat-enabled service allows multiple registrations for the same user" do
    temple = create_temple(
      metadata: {
        "registration_periods" => [
          { "key" => "perennial", "label_zh" => "常年供燈", "label_en" => "Perennial" }
        ]
      }
    )
    offering = temple.temple_services.create!(
      slug: "incense-donation",
      title: "香油捐獻",
      description: "敬獻香油",
      currency: "TWD",
      price_cents: 300,
      status: "published",
      registration_period_key: "perennial",
      period_label: "常年供燈",
      metadata: {
        "allow_repeat_registrations" => true
      }
    )
    user = User.create!(
      email: "repeat@example.com",
      english_name: "Repeat Member",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    assert_difference -> { TempleEventRegistration.count }, 1 do
      post account_registrations_path, params: {
        offering: offering.slug,
        account_action: "service",
        account_registration_intake_form: {
          contact_name: "Repeat Member",
          quantity: 1
        }
      }
    end

    assert_difference -> { TempleEventRegistration.count }, 1 do
      post account_registrations_path, params: {
        offering: offering.slug,
        account_action: "service",
        account_registration_intake_form: {
          contact_name: "Repeat Member",
          quantity: 1
        }
      }
    end

    registrations = TempleEventRegistration.where(user: user, registrable: offering).order(:created_at)
    assert_equal 2, registrations.count
    assert_redirected_to payment_account_registration_path(registrations.last)
  end
end
