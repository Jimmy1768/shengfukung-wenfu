require "test_helper"

class AdminPaymentsFlowTest < ActionDispatch::IntegrationTest
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

  test "records cash payment through admin controller" do
    temple = create_temple
    offering = create_offering(temple:, slug: "lamp", title: "Lamp", price_cents: 700)
    user = User.create!(
      email: "cashflow-user@example.com",
      english_name: "Cash Flow User",
      encrypted_password: User.password_hash("Password123!")
    )
    registration = create_registration(user:, offering:)
    admin_user = create_admin_user(temple:)
    permission = AdminPermission.find_by(admin_account: admin_user.admin_account, temple:)
    permission.update!(record_cash_payments: true)

    sign_in_admin(admin_user)

    post admin_payments_path(registration_id: registration.id),
      params: { temple_payment: { amount_cents: 700, currency: "TWD" } }

    assert_redirected_to admin_event_offering_order_path(offering, registration)
    assert_equal "paid", registration.reload.payment_status
    assert_equal 1, registration.temple_payments.count
  end

  test "starts checkout through admin controller" do
    temple = create_temple
    offering = create_offering(temple:, slug: "admin-fake", title: "Admin Fake", price_cents: 900)
    user = User.create!(
      email: "adminfake-user@example.com",
      english_name: "Admin Fake User",
      encrypted_password: User.password_hash("Password123!")
    )
    registration = create_registration(user:, offering:)
    admin_user = create_admin_user(temple:)
    permission = AdminPermission.find_by(admin_account: admin_user.admin_account, temple:)
    permission.update!(record_cash_payments: true)

    sign_in_admin(admin_user)

    post start_checkout_admin_payments_path(registration_id: registration.id)

    assert_redirected_to admin_event_offering_order_path(offering, registration)
    payment = registration.temple_payments.order(:created_at).last
    assert_not_nil payment
    assert_equal "fake", payment.provider
    assert_equal TemplePayment::STATUSES[:pending], payment.status
  end

  test "start checkout redirects to provider checkout url when present" do
    temple = create_temple
    offering = create_offering(temple:, slug: "admin-redirect", title: "Admin Redirect", price_cents: 950)
    user = User.create!(
      email: "adminredirect-user@example.com",
      english_name: "Admin Redirect User",
      encrypted_password: User.password_hash("Password123!")
    )
    registration = create_registration(user:, offering:)
    admin_user = create_admin_user(temple:)
    permission = AdminPermission.find_by(admin_account: admin_user.admin_account, temple:)
    permission.update!(record_cash_payments: true)

    sign_in_admin(admin_user)

    Payments::ProviderResolver.stub(:current_provider, "line_pay") do
      PaymentGateway::LinePayAdapter.stub(:new, FakeRedirectAdapter.new("https://pay.example.test/admin")) do
        post start_checkout_admin_payments_path(registration_id: registration.id)
      end
    end

    assert_redirected_to "https://pay.example.test/admin"
  end

  test "checkout return confirms payment and redirects back to admin order" do
    temple = create_temple
    offering = create_offering(temple:, slug: "admin-line-return", title: "Admin Line Return", price_cents: 1000)
    user = User.create!(
      email: "admin-line-return@example.com",
      english_name: "Admin Line Return",
      encrypted_password: User.password_hash("Password123!")
    )
    registration = create_registration(user:, offering:)
    create_payment(
      registration: registration,
      amount_cents: registration.total_price_cents,
      status: TemplePayment::STATUSES[:pending],
      method: TemplePayment::PAYMENT_METHODS[:line_pay],
      provider: "line_pay",
      provider_reference: "order_admin_1",
      processed_at: nil
    )
    admin_user = create_admin_user(temple:)
    permission = AdminPermission.find_by(admin_account: admin_user.admin_account, temple:)
    permission.update!(record_cash_payments: true)

    sign_in_admin(admin_user)

    PaymentGateway::LinePayAdapter.stub(:new, FakeReturnAdapter.new("completed")) do
      get checkout_return_admin_payments_path(registration_id: registration.id, provider: "line_pay", transactionId: "tx_admin_1", orderId: "order_admin_1")
    end

    assert_redirected_to admin_event_offering_order_path(offering, registration)
    assert_equal TempleRegistration::PAYMENT_STATUSES[:paid], registration.reload.payment_status
    assert_equal TemplePayment::STATUSES[:completed], registration.temple_payments.order(:created_at).last.reload.status
  end
end
