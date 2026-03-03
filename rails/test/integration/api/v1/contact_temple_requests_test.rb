# frozen_string_literal: true

require "test_helper"
require "zlib"

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

  test "public site request is blocked by shared api protection when IP is blacklisted" do
    temple = create_temple
    fake_client = FakeBrevoClient.new([])
    ip = "198.51.100.19"
    BlacklistEntry.create!(
      scope_type: "IpAddress",
      scope_id: Zlib.crc32(ip),
      reason: "test_block",
      active: true,
      expires_at: 1.hour.from_now
    )

    Notifications::BrevoClient.stub(:new, fake_client) do
      post "/api/v1/temples/#{temple.slug}/contact_temple_requests",
        params: {
          name: "Public Visitor",
          email: "visitor@example.com",
          subject: "Rate limit test",
          message: "This message should be blocked by shared api protection.",
          website: ""
        },
        headers: { "REMOTE_ADDR" => ip },
        as: :json
    end

    assert_response :too_many_requests
    assert_equal 0, fake_client.calls.size
  end
end
