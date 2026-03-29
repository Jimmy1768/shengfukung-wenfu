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

  test "paid gathering registration redirects to payment page" do
    temple = create_temple
    gathering = temple.temple_gatherings.create!(
      slug: "community-workshop",
      title: "Community Workshop",
      currency: "TWD",
      price_cents: 450,
      status: "published",
      starts_on: Date.current
    )
    user = User.create!(
      email: "gatheringflow@example.com",
      english_name: "Gathering Flow Member",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    assert_difference -> { TempleEventRegistration.count }, 1 do
      post account_registrations_path, params: {
        offering: gathering.slug,
        account_action: "gathering",
        account_registration_intake_form: {
          contact_name: "Gathering Flow Member",
          quantity: 1
        }
      }
    end

    registration = TempleEventRegistration.order(:created_at).last
    assert_equal gathering, registration.registrable
    assert_redirected_to payment_account_registration_path(registration)

    follow_redirect!
    assert_response :success
    assert_includes response.body, "前往付款"
    assert_includes response.body, gathering.title
  end

  test "new gathering registration honors temple param and active account temple context" do
    create_temple(slug: "decoy-temple", name: "Decoy Temple")
    temple = create_temple(slug: "selected-temple", name: "Selected Temple")
    gathering = temple.temple_gatherings.create!(
      slug: "selected-gathering",
      title: "Selected Gathering",
      currency: "TWD",
      price_cents: 450,
      status: "published",
      starts_on: Date.current
    )
    user = User.create!(
      email: "templecontext@example.com",
      english_name: "Temple Context Member",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    get new_account_registration_path(
      temple: temple.slug,
      account_action: "gathering",
      offering: gathering.slug
    )

    assert_response :success
    assert_includes response.body, gathering.title
    assert_select "input[name='account_registration_intake_form[contact_name]']"
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

  test "free gathering registration payment page shows confirmation" do
    temple = create_temple
    gathering = temple.temple_gatherings.create!(
      slug: "free-community-tea",
      title: "Free Community Tea",
      currency: "TWD",
      price_cents: 0,
      status: "published",
      starts_on: Date.current
    )
    user = User.create!(
      email: "freegathering@example.com",
      english_name: "Free Gathering Member",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    post account_registrations_path, params: {
      offering: gathering.slug,
      account_action: "gathering",
      account_registration_intake_form: {
        contact_name: "Free Gathering Member",
        quantity: 1
      }
    }

    registration = TempleEventRegistration.order(:created_at).last
    assert_equal gathering, registration.registrable
    assert_redirected_to payment_account_registration_path(registration)

    follow_redirect!
    assert_response :success
    assert_includes response.body, "此報名不需付費，已完成。"
  end

  test "failed payment page shows retry action" do
    temple = create_temple
    offering = create_offering(temple:, slug: "failed-payment", title: "Failed Payment Offering", price_cents: 700)
    user = User.create!(
      email: "failedpayment@example.com",
      english_name: "Failed Payment",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)
    registration = create_registration(user:, offering:, payment_status: TempleRegistration::PAYMENT_STATUSES[:failed])

    get payment_account_registration_path(registration)

    assert_response :success
    assert_includes response.body, "付款失敗"
    assert_includes response.body, "重新付款"
  end

  test "start fake checkout redirects through return flow and marks payment paid" do
    temple = create_temple
    offering = create_offering(temple:, slug: "fake-checkout", title: "Fake Checkout Offering", price_cents: 800)
    user = User.create!(
      email: "fakecheckout@example.com",
      english_name: "Fake Checkout",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)
    registration = create_registration(user:, offering:)

    assert_difference -> { SystemAuditLog.where(action: "account.payments.checkout_started").count }, 1 do
      post start_checkout_account_registration_path(registration)
    end

    assert_redirected_to checkout_return_account_registration_url(registration, provider: "fake")
    follow_redirect!
    assert_redirected_to payment_account_registration_path(registration)
    follow_redirect!
    assert_response :success
    payment = registration.temple_payments.order(:created_at).last
    assert_not_nil payment
    assert_equal "fake", payment.provider
    assert_equal TemplePayment::STATUSES[:completed], payment.reload.status
    assert_equal TempleRegistration::PAYMENT_STATUSES[:paid], registration.reload.payment_status
    assert_includes response.body, "Payment confirmed successfully."
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
        assert_difference -> { SystemAuditLog.where(action: "account.payments.checkout_started").count }, 1 do
          post start_checkout_account_registration_path(registration)
        end
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

    assert_difference -> { SystemAuditLog.where(action: "account.payments.checkout_returned").count }, 1 do
      assert_difference -> { SystemAuditLog.where(action: "system.payments.reconciled").count }, 1 do
        PaymentGateway::LinePayAdapter.stub(:new, FakeReturnAdapter.new("completed")) do
          get checkout_return_account_registration_path(registration, provider: "line_pay", transactionId: "tx_123", orderId: "order_123")
        end
      end
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
