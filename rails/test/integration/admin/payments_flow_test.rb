require "test_helper"

class AdminPaymentsFlowTest < ActionDispatch::IntegrationTest
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

  test "starts fake checkout through admin controller" do
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

    post fake_checkout_admin_payments_path(registration_id: registration.id)

    assert_redirected_to admin_event_offering_order_path(offering, registration)
    payment = registration.temple_payments.order(:created_at).last
    assert_not_nil payment
    assert_equal "fake", payment.provider
    assert_equal TemplePayment::STATUSES[:pending], payment.status
  end
end
