# frozen_string_literal: true

require "test_helper"

class Api::V1::ContactTempleRequestsTest < ActionDispatch::IntegrationTest
  FakeBrevoClient = Struct.new(:calls) do
    def send_email(**kwargs)
      calls << kwargs
      true
    end
  end

  test "public site visitor can submit contact temple request" do
    temple = create_temple
    fake_client = FakeBrevoClient.new([])

    Notifications::BrevoClient.stub(:new, fake_client) do
      post "/api/v1/temples/#{temple.slug}/contact_temple_requests",
        params: {
          name: "Public Visitor",
          email: "visitor@example.com",
          subject: "Question from public site",
          message: "Hello temple, I have a question from the website.",
          website: ""
        },
        as: :json
    end

    assert_response :created
    assert_equal 2, fake_client.calls.size
    assert_equal AppConstants::Emails.support_email, fake_client.calls.first.dig(:to, :email)
    assert_equal "visitor@example.com", fake_client.calls.second.dig(:to, :email)
  end

  test "public site falls back to global support email when temple email missing" do
    temple = create_temple
    fake_client = FakeBrevoClient.new([])

    Notifications::BrevoClient.stub(:new, fake_client) do
      post "/api/v1/temples/#{temple.slug}/contact_temple_requests",
        params: {
          name: "Public Visitor",
          email: "visitor@example.com",
          subject: "Fallback recipient test",
          message: "Testing fallback recipient routing for missing temple email.",
          website: ""
        },
        as: :json
    end

    assert_response :created
    assert_equal AppConstants::Emails.support_email, fake_client.calls.first.dig(:to, :email)
  end

  test "public site invalid payload returns validation error" do
    temple = create_temple
    fake_client = FakeBrevoClient.new([])

    Notifications::BrevoClient.stub(:new, fake_client) do
      post "/api/v1/temples/#{temple.slug}/contact_temple_requests",
        params: {
          name: "",
          email: "not-an-email",
          subject: "",
          message: "short",
          website: ""
        },
        as: :json
    end

    assert_response :unprocessable_entity
    assert_equal 0, fake_client.calls.size
    assert_includes response.parsed_body["error"], "Please check"
  end

  test "public site rate limiting blocks abusive bursts" do
    temple = create_temple
    fake_client = FakeBrevoClient.new([])
    denied_result = Contact::TempleInquiryRateLimiter::Result.new(allowed?: false, reason: :ip_limit)

    Contact::TempleInquiryRateLimiter.stub(:call, denied_result) do
      Notifications::BrevoClient.stub(:new, fake_client) do
        post "/api/v1/temples/#{temple.slug}/contact_temple_requests",
          params: {
            name: "Public Visitor",
            email: "visitor@example.com",
            subject: "Rate limit test",
            message: "This message should be blocked by rate limiting.",
            website: ""
          },
          as: :json
      end
    end

    assert_response :too_many_requests
    assert_equal 0, fake_client.calls.size
  end
end
