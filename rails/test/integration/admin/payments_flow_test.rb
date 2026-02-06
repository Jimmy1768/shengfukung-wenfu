require "test_helper"

class AdminPaymentsFlowTest < ActionDispatch::IntegrationTest
  test "records cash payment through admin controller" do
    temple = create_temple
    offering = TempleOffering.create!(temple:, slug: "lamp", title: "Lamp", currency: "TWD", price_cents: 700)
    registration = TempleEventRegistration.create!(
      temple:,
      temple_offering: offering,
      quantity: 1,
      contact_payload: {},
      logistics_payload: {},
      metadata: {}
    )
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
end
