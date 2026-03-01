require "test_helper"

class RegistrationPaymentFlowTest < ActionDispatch::IntegrationTest
  test "successful registration redirects to payment page" do
    temple = create_temple
    offering = TempleOffering.create!(
      temple:,
      slug: "lantern-festival",
      title: "Lantern Festival",
      currency: "TWD",
      price_cents: 600,
      starts_on: Date.current,
      ends_on: Date.current + 1.day
    )
    user = User.create!(
      email: "flow@example.com",
      english_name: "Flow Member",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    post account_registrations_path, params: {
      offering: offering.slug,
      account_action: "event",
      account_registration_intake_form: {
        contact_name: "Flow Member",
        quantity: 1
      }
    }

    registration = TempleEventRegistration.order(:created_at).last
    assert_redirected_to payment_account_registration_path(registration)

    follow_redirect!
    assert_response :success
    assert_includes response.body, "Pay with LINE Pay"
    assert_includes response.body, offering.title
  end

  test "free registration payment page shows confirmation" do
    temple = create_temple
    offering = TempleOffering.create!(
      temple:,
      slug: "community-potluck",
      title: "Community Potluck",
      currency: "TWD",
      price_cents: 0,
      starts_on: Date.current,
      ends_on: Date.current + 1.day
    )
    user = User.create!(
      email: "free@example.com",
      english_name: "Free Member",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    post account_registrations_path, params: {
      offering: offering.slug,
      account_action: "event",
      account_registration_intake_form: {
        contact_name: "Free Member",
        quantity: 1
      }
    }

    registration = TempleEventRegistration.order(:created_at).last
    assert_redirected_to payment_account_registration_path(registration)

    follow_redirect!
    assert_response :success
    assert_includes response.body, "This registration is free"
  end

  test "start fake checkout creates pending payment and stays on payment page" do
    temple = create_temple
    offering = create_offering(temple:, slug: "fake-checkout", title: "Fake Checkout Offering", price_cents: 800)
    user = User.create!(
      email: "fakecheckout@example.com",
      english_name: "Fake Checkout",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)
    registration = create_registration(user:, offering:)

    post start_fake_checkout_account_registration_path(registration)

    assert_redirected_to payment_account_registration_path(registration)
    payment = registration.temple_payments.order(:created_at).last
    assert_not_nil payment
    assert_equal "fake", payment.provider
    assert_equal TemplePayment::STATUSES[:pending], payment.status
    assert_equal TempleRegistration::PAYMENT_STATUSES[:pending], registration.reload.payment_status
  end
end
