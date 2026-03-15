require "test_helper"

module Account
  class AssistanceRequestsTest < ActionDispatch::IntegrationTest
    test "signed in user can create registration-scoped assistance request" do
      temple = create_temple(slug: "assist-reg-temple")
      user = User.create!(
        email: "assist-reg@example.com",
        english_name: "Assist Reg",
        encrypted_password: User.password_hash("Password123!")
      )
      offering = temple.temple_services.create!(
        slug: "assist-service",
        title: "Assist Service",
        description: "Desc",
        status: "active",
        price_cents: 100,
        currency: "TWD"
      )
      registration = TempleEventRegistration.create!(
        temple: temple,
        registrable: offering,
        user: user,
        reference_code: "REG-HELP1",
        quantity: 1,
        unit_price_cents: 100,
        total_price_cents: 100,
        currency: "TWD",
        payment_status: "pending",
        fulfillment_status: "open"
      )

      sign_in_account(user, temple_slug: temple.slug)

      post account_assistance_requests_path, params: {
        account_assistance_request: {
          registration_id: registration.id,
          channel: "registration_detail"
        }
      }

      assert_redirected_to account_registration_path(registration)
      request_record = TempleAssistanceRequest.find_by!(temple: temple, user: user, temple_registration: registration)
      assert_equal "open", request_record.status
      assert_equal "registration_detail", request_record.channel
    end

    test "duplicate open assistance request is reused" do
      temple = create_temple(slug: "assist-dup-temple")
      user = User.create!(
        email: "assist-dup@example.com",
        english_name: "Assist Dup",
        encrypted_password: User.password_hash("Password123!")
      )

      TempleAssistanceRequest.create!(
        temple: temple,
        user: user,
        status: "open",
        requested_at: Time.current,
        channel: "profile"
      )

      sign_in_account(user, temple_slug: temple.slug)

      post account_assistance_requests_path, params: {
        account_assistance_request: {
          channel: "profile",
          message: "Need help"
        }
      }

      assert_redirected_to account_profile_path
      assert_equal 1, TempleAssistanceRequest.where(temple: temple, user: user, status: "open").count
    end
  end
end
