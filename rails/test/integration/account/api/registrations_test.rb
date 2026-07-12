# frozen_string_literal: true

require "test_helper"

class Account::Api::RegistrationsTest < ActionDispatch::IntegrationTest
  test "returns the signed-in user's registrations" do
    temple = create_temple
    offering = create_offering(temple:)
    user = create_admin_user(temple:, role: "admin")
    registration = create_registration(user:, offering:)

    sign_in_account(user)
    get api_v1_account_registrations_path

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal 1, payload["registrations"].length
    entry = payload["registrations"].first
    assert_equal registration.reference_code, entry["reference_code"]
    assert_equal registration.payment_status, entry["payment_status"]
  end

  test "owner only sees temple-wide registrations for temples they own" do
    alpha = create_temple(name: "Alpha Temple", slug: "alpha-temple")
    beta = create_temple(name: "Beta Temple", slug: "beta-temple")
    alpha_offering = create_offering(temple: alpha, slug: "alpha-offering")
    beta_offering = create_offering(temple: beta, slug: "beta-offering")
    owner = create_admin_user(temple: alpha, role: "owner")
    other_user = User.create!(
      email: "cross-temple-owner@example.com",
      english_name: "Cross Temple Patron",
      encrypted_password: User.password_hash("Password123!")
    )

    AdminTempleMembership.create!(
      admin_account: owner.admin_account,
      temple: beta,
      role: "admin"
    )
    AdminPermission.create!(
      admin_account: owner.admin_account,
      temple: beta,
      manage_offerings: true,
      manage_registrations: true
    )

    alpha_registration = create_registration(user: other_user, offering: alpha_offering)
    beta_registration = create_registration(user: other_user, offering: beta_offering)

    sign_in_account(owner)
    get api_v1_account_registrations_path

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal [alpha_registration.reference_code], payload["registrations"].map { |entry| entry["reference_code"] }
    refute_includes payload["registrations"].map { |entry| entry["reference_code"] }, beta_registration.reference_code
  end
end
