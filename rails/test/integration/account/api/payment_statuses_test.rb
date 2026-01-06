# frozen_string_literal: true

require "test_helper"

class Account::Api::PaymentStatusesTest < ActionDispatch::IntegrationTest
  test "returns payment status for the user's registration" do
    temple = create_temple
    offering = create_offering(temple:)
    user = create_admin_user(temple:, role: "staff")
    registration = create_registration(user:, offering:, payment_status: "paid")
    create_payment(registration:, amount_cents: registration.total_price_cents)

    sign_in_account(user)
    get account_api_payment_status_path(reference: registration.reference_code)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal "paid", payload["payment_status"]
    assert_equal registration.total_price_cents, payload["total_amount_cents"]
    assert_equal 1, payload["payments"].length
  end

  test "returns 404 when registration is not accessible" do
    temple = create_temple
    offering = create_offering(temple:)
    user = create_admin_user(temple:, role: "staff")
    other_user = create_admin_user(temple:, role: "staff")
    other_registration = create_registration(user: other_user, offering:)
    create_registration(user:, offering:)

    sign_in_account(user)
    get account_api_payment_status_path(reference: other_registration.reference_code)

    assert_response :not_found
  end
end
