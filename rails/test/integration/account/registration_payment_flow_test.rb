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
    assert_includes response.body, "使用 LINE Pay 付款"
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
    assert_includes response.body, "此報名不需付費，已完成。"
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

  test "repeat-enabled service allows multiple registrations for the same user" do
    temple = create_temple(
      metadata: {
        "registration_periods" => [
          { "key" => "perennial", "label_zh" => "常年供燈", "label_en" => "Perennial" }
        ]
      }
    )
    offering = temple.temple_services.create!(
      slug: "incense-donation",
      title: "香油捐獻",
      description: "敬獻香油",
      currency: "TWD",
      price_cents: 300,
      status: "published",
      registration_period_key: "perennial",
      period_label: "常年供燈",
      metadata: {
        "allow_repeat_registrations" => true
      }
    )
    user = User.create!(
      email: "repeat@example.com",
      english_name: "Repeat Member",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    assert_difference -> { TempleEventRegistration.count }, 1 do
      post account_registrations_path, params: {
        offering: offering.slug,
        account_action: "service",
        account_registration_intake_form: {
          contact_name: "Repeat Member",
          quantity: 1
        }
      }
    end

    assert_difference -> { TempleEventRegistration.count }, 1 do
      post account_registrations_path, params: {
        offering: offering.slug,
        account_action: "service",
        account_registration_intake_form: {
          contact_name: "Repeat Member",
          quantity: 1
        }
      }
    end

    registrations = TempleEventRegistration.where(user: user, registrable: offering).order(:created_at)
    assert_equal 2, registrations.count
    assert_redirected_to payment_account_registration_path(registrations.last)
  end
end
