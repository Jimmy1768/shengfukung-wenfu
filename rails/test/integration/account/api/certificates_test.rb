# frozen_string_literal: true

require "test_helper"

class Account::Api::CertificatesTest < ActionDispatch::IntegrationTest
  test "lists certificates for the current user" do
    temple = create_temple
    offering = create_offering(temple:)
    user = create_admin_user(temple:, role: "admin")
    create_registration(user:, offering:, certificate_number: "CERT-123")

    sign_in_account(user)
    get account_api_certificates_path

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal ["CERT-123"], payload["certificates"].map { |entry| entry["certificate_number"] }
  end
end
