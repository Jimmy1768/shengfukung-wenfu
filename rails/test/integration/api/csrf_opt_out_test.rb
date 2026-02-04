require "test_helper"

class ApiCsrfOptOutTest < ActionDispatch::IntegrationTest
  setup do
    @previous_allow_forgery = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @previous_allow_forgery
  end

  test "JSON API endpoints accept POST without authenticity token" do
    result = Struct.new(:success?, :locale_key, :error_code).new(true, :en, nil)
    fake_sender = Struct.new(:result) do
      def call(*)
        result
      end
    end.new(result)

    Contact::DemoInquirySender.stub :new, ->(*) { fake_sender } do
      post api_v1_demo_contacts_path, params: {
        email: "demo@example.com",
        name: "Demo User",
        locale: "en",
        message: "Interested in a walkthrough"
      }
    end

    assert_response :created
  end
end
