require "test_helper"

class AccountPortalFlowTest < ActionDispatch::IntegrationTest
  test "member sees registrations and payments and can update metadata" do
    temple = create_temple
    offering = create_offering(
      temple:,
      slug: "spring-lights",
      title: "新春點燈",
      price_cents: 800
    )
    user = User.create!(
      email: "member@example.com",
      english_name: "Member",
      encrypted_password: User.password_hash("Password123!")
    )
    registration = create_registration(
      user:,
      offering:,
      quantity: 1,
      contact_payload: { "primary_contact" => "Member" },
      logistics_payload: {},
      certificate_number: "CERT-001"
    )
    create_payment(
      registration:,
      method: TemplePayment::PAYMENT_METHODS[:line_pay],
      provider: "line_pay"
    )

    gallery_entry = temple.temple_gallery_entries.create!(
      title: "Lantern Parade",
      body: "Volunteers gathered at dusk.",
      event_date: Date.current,
      photo_urls: ["https://placehold.co/1200x800/f97316/ffffff?text=Gallery"]
    )

    sign_in_account(user, temple_slug: temple.slug)

    get account_dashboard_path
    assert_response :success
    assert_includes response.body, "新春點燈"
    assert_includes response.body, "CERT-001"

    get account_payments_path
    assert_response :success
    assert_includes response.body, "LINE Pay"

    get account_registrations_path
    assert_response :success
    assert_includes response.body, registration.reference_code

    get edit_account_registration_path(registration)
    assert_response :success

    patch account_registration_path(registration), params: {
      account_registration_metadata_form: {
        contact_name: "Member",
        contact_phone: "0912-000-000",
        contact_email: "member@example.com",
        household_notes: "2 位家人",
        arrival_window: "08:30",
        ceremony_notes: "Need seating"
      }
    }
    assert_redirected_to account_registration_path(registration)

    registration.reload
    assert_equal "0912-000-000", registration.contact_payload["phone"]
    assert_equal "Need seating", registration.metadata["ceremony_notes"]

    get account_galleries_path
    assert_response :success
    assert_includes response.body, gallery_entry.title

    get account_gallery_path(gallery_entry)
    assert_response :success
    assert_includes response.body, gallery_entry.title
  end
end
