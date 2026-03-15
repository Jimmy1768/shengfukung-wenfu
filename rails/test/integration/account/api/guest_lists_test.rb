# frozen_string_literal: true

require "test_helper"

class Account::Api::GuestListsTest < ActionDispatch::IntegrationTest
  test "returns guest list for admins with permission" do
    temple = create_temple
    offering = create_offering(temple:, slug: "spring")
    owner = create_admin_user(temple:, permission_overrides: { view_guest_lists: true })
    registration = create_registration(user: owner, offering:, certificate_number: "CERT-GL")

    sign_in_account(owner)
    get account_api_guest_list_path(offering.slug)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal offering.title, payload["offering"]["title"]
    assert_equal registration.reference_code, payload["registrations"].first["reference_code"]
  end

  test "blocks access when admin lacks capability" do
    temple = create_temple
    offering = create_offering(temple:)
    staff = create_admin_user(
      temple:,
      role: "admin",
      membership_role: "admin",
      permission_overrides: { view_guest_lists: false }
    )

    sign_in_account(staff)
    get account_api_guest_list_path(offering.slug)

    assert_response :forbidden
  end
end
