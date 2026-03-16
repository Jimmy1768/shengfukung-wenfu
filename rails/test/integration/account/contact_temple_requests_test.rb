# frozen_string_literal: true

require "test_helper"

class Account::ContactTempleRequestsTest < ActionDispatch::IntegrationTest
  FakeBrevoClient = Struct.new(:calls) do
    def send_email(**kwargs)
      calls << kwargs
      true
    end
  end

  test "signed-in account user can submit contact temple request" do
    temple = create_temple
    user = create_admin_user(temple:)
    fake_client = FakeBrevoClient.new([])

    sign_in_account(user, temple_slug: temple.slug)

    Notifications::BrevoClient.stub(:new, fake_client) do
      assert_difference -> { SystemAuditLog.where(action: "account.contact_temple_requests.created").count }, 1 do
        post account_contact_temple_requests_path,
          params: {
            return_to: account_events_path,
            account_contact_temple_request_form: {
              subject: "Question about registration",
              message: "Hello temple, I need help with tomorrow's registration.",
              website: ""
            }
          }
      end
    end

    assert_redirected_to account_events_path
    follow_redirect!
    assert_includes response.body, "message has been sent"

    assert_equal 2, fake_client.calls.size
    temple_email = fake_client.calls.first.dig(:to, :email)
    patron_email = fake_client.calls.second.dig(:to, :email)
    assert_equal AppConstants::Emails.support_email, temple_email
    assert_equal user.email, patron_email
    log = SystemAuditLog.order(created_at: :desc).find_by(action: "account.contact_temple_requests.created")
    assert_equal temple, log.temple
    assert_equal true, log.metadata["subject_present"]
  end

  test "invalid payload does not send emails" do
    temple = create_temple
    user = create_admin_user(temple:)
    fake_client = FakeBrevoClient.new([])

    sign_in_account(user, temple_slug: temple.slug)

    Notifications::BrevoClient.stub(:new, fake_client) do
      post account_contact_temple_requests_path,
        params: {
          account_contact_temple_request_form: {
            subject: "",
            message: "short",
            website: ""
          }
        }
    end

    assert_response :unprocessable_content
    assert_equal 0, fake_client.calls.size
    assert_includes response.body, "Please check the form and try again."
  end

  test "development email override routes both recipients to dev email" do
    temple = create_temple
    user = create_admin_user(temple:)
    fake_client = FakeBrevoClient.new([])

    sign_in_account(user, temple_slug: temple.slug)

    Rails.env.stub(:development?, true) do
      ENV["DEV_EMAIL"] = "jimmy.chuang@outlook.com"
      Notifications::BrevoClient.stub(:new, fake_client) do
        post account_contact_temple_requests_path,
          params: {
            account_contact_temple_request_form: {
              subject: "Dev email test",
              message: "Testing the dev email recipient override behavior.",
              website: ""
            }
          }
      end
    ensure
      ENV.delete("DEV_EMAIL")
    end

    assert_redirected_to account_profile_path
    assert_equal 2, fake_client.calls.size
    assert_equal "jimmy.chuang@outlook.com", fake_client.calls.first.dig(:to, :email)
    assert_equal "jimmy.chuang@outlook.com", fake_client.calls.second.dig(:to, :email)
  end
end
