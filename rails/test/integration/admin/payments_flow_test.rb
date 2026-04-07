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

    def query_status(provider_payment_ref:, **)
      {
        status: status,
        provider_reference: provider_payment_ref,
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

    assert_difference -> { SystemAuditLog.where(action: "admin.payments.created").count }, 1 do
      post admin_payments_path(registration_id: registration.id),
        params: { temple_payment: { amount_cents: 700, currency: "TWD" } }
    end

    assert_redirected_to admin_event_offering_order_path(offering, registration)
    assert_equal "paid", registration.reload.payment_status
    assert_equal 1, registration.temple_payments.count
  end

  test "starts fake checkout through admin controller and confirms payment" do
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

    assert_difference -> { SystemAuditLog.where(action: "admin.payments.checkout_started").count }, 1 do
      post start_checkout_admin_payments_path(registration_id: registration.id)
    end

    assert_redirected_to checkout_return_admin_payments_url(registration_id: registration.id, provider: "fake")
    follow_redirect!
    assert_redirected_to admin_event_offering_order_path(offering, registration)
    payment = registration.temple_payments.order(:created_at).last
    assert_not_nil payment
    assert_equal "fake", payment.provider
    assert_equal TemplePayment::STATUSES[:completed], payment.reload.status
    assert_equal TempleRegistration::PAYMENT_STATUSES[:paid], registration.reload.payment_status
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

    Payments::ProviderResolver.stub(:current_provider, "ecpay") do
      PaymentGateway::EcpayAdapter.stub(:new, FakeRedirectAdapter.new("/payments/ecpay_checkouts/admin")) do
        assert_difference -> { SystemAuditLog.where(action: "admin.payments.checkout_started").count }, 1 do
          post start_checkout_admin_payments_path(registration_id: registration.id)
        end
      end
    end

    assert_redirected_to "/payments/ecpay_checkouts/admin"
  end

  test "checkout return confirms ecpay payment and redirects back to admin order" do
    temple = create_temple
    offering = create_offering(temple:, slug: "admin-ecpay-return", title: "Admin ECPay Return", price_cents: 1000)
    user = User.create!(
      email: "admin-ecpay-return@example.com",
      english_name: "Admin ECPay Return",
      encrypted_password: User.password_hash("Password123!")
    )
    registration = create_registration(user:, offering:)
    create_payment(
      registration: registration,
      amount_cents: registration.total_price_cents,
      status: TemplePayment::STATUSES[:pending],
      method: TemplePayment::PAYMENT_METHODS[:ecpay],
      provider: "ecpay",
      provider_reference: "trade_admin_1",
      processed_at: nil
    )
    admin_user = create_admin_user(temple:)
    permission = AdminPermission.find_by(admin_account: admin_user.admin_account, temple:)
    permission.update!(record_cash_payments: true)

    sign_in_admin(admin_user)

    assert_difference -> { SystemAuditLog.where(action: "admin.payments.checkout_returned").count }, 1 do
      assert_difference -> { SystemAuditLog.where(action: "system.payments.reconciled").count }, 1 do
        PaymentGateway::EcpayAdapter.stub(:new, FakeReturnAdapter.new("completed")) do
          post checkout_return_admin_payments_path(
            registration_id: registration.id,
            provider: "ecpay",
            MerchantTradeNo: "trade_admin_1",
            TradeNo: "ecpay_admin_trade_no_1",
            RtnCode: "1",
            TradeStatus: "1",
            CheckMacValue: "mac_admin_1"
          )
        end
      end
    end

    assert_redirected_to admin_event_offering_order_path(offering, registration)
    assert_equal TempleRegistration::PAYMENT_STATUSES[:paid], registration.reload.payment_status
    assert_equal TemplePayment::STATUSES[:completed], registration.temple_payments.order(:created_at).last.reload.status
  end

  test "ecpay checkout return for gathering redirects back to gathering order" do
    temple = create_temple
    gathering = temple.temple_gatherings.create!(
      slug: "admin-gathering-ecpay-return",
      title: "Admin Gathering Return",
      currency: "TWD",
      price_cents: 550,
      status: "published"
    )
    user = User.create!(
      email: "admin-gathering-line-return@example.com",
      english_name: "Admin Gathering Return",
      encrypted_password: User.password_hash("Password123!")
    )
    registration = create_registration(user:, offering: gathering)
    create_payment(
      registration: registration,
      amount_cents: registration.total_price_cents,
      status: TemplePayment::STATUSES[:pending],
      method: TemplePayment::PAYMENT_METHODS[:ecpay],
      provider: "ecpay",
      provider_reference: "trade_admin_gathering_1",
      processed_at: nil
    )
    admin_user = create_admin_user(temple:)
    permission = AdminPermission.find_by(admin_account: admin_user.admin_account, temple:)
    permission.update!(record_cash_payments: true)

    sign_in_admin(admin_user)

    assert_difference -> { SystemAuditLog.where(action: "admin.payments.checkout_returned").count }, 1 do
      assert_difference -> { SystemAuditLog.where(action: "system.payments.reconciled").count }, 1 do
        PaymentGateway::EcpayAdapter.stub(:new, FakeReturnAdapter.new("completed")) do
          post checkout_return_admin_payments_path(
            registration_id: registration.id,
            provider: "ecpay",
            MerchantTradeNo: "trade_admin_gathering_1",
            TradeNo: "ecpay_admin_gathering_trade_no_1",
            RtnCode: "1",
            TradeStatus: "1",
            CheckMacValue: "mac_admin_gathering_1"
          )
        end
      end
    end

    assert_redirected_to admin_gathering_offering_order_path(gathering, registration)
    assert_equal TempleRegistration::PAYMENT_STATUSES[:paid], registration.reload.payment_status
    assert_equal TemplePayment::STATUSES[:completed], registration.temple_payments.order(:created_at).last.reload.status
  end
end
