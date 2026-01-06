# frozen_string_literal: true

require "test_helper"

class Account::Api::RegistrationsTest < ActionDispatch::IntegrationTest
  test "returns the signed-in user's registrations" do
    temple = create_temple
    offering = create_offering(temple:)
    user = create_admin_user(temple:, role: "staff")
    registration = create_registration(user:, offering:)

    sign_in_account(user)
    get account_api_registrations_path

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal 1, payload["registrations"].length
    entry = payload["registrations"].first
    assert_equal registration.reference_code, entry["reference_code"]
    assert_equal registration.payment_status, entry["payment_status"]
  end
end
