# frozen_string_literal: true

require "test_helper"

class ControllerNamespaceGuardrailsTest < ActionDispatch::IntegrationTest
  test "public and account programmatic endpoints route under api v1" do
    assert_equal(
      { format: :json, controller: "api/v1/temples", action: "show", slug: "demo" },
      Rails.application.routes.recognize_path("/api/v1/temples/demo", method: :get)
    )

    assert_equal(
      { format: :json, controller: "api/v1/account/registrations", action: "index" },
      Rails.application.routes.recognize_path("/api/v1/account/registrations", method: :get)
    )

    assert_equal(
      { format: :json, controller: "api/v1/account/payment_statuses", action: "show", reference: "ABC123" },
      Rails.application.routes.recognize_path("/api/v1/account/payment_statuses/ABC123", method: :get)
    )
  end

  test "legacy account api routes are not routable" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/account/api/registrations", method: :get)
    end

    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/account/api/payment_statuses/ABC123", method: :get)
    end
  end

  test "marketing admin showcase routes to demo controllers" do
    assert_equal(
      { controller: "demo/sessions", action: "new" },
      Rails.application.routes.recognize_path("/marketing/admin", method: :get)
    )

    assert_equal(
      { controller: "demo/dashboard", action: "index" },
      Rails.application.routes.recognize_path("/marketing/admin/dashboard", method: :get)
    )
  end

  test "html namespaces remain unversioned" do
    assert_equal(
      { format: :html, controller: "account/dashboard", action: "index" },
      Rails.application.routes.recognize_path("/account/dashboard", method: :get)
    )

    assert_equal(
      { format: :html, controller: "admin/dashboard", action: "index" },
      Rails.application.routes.recognize_path("/admin/dashboard", method: :get)
    )

    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/account/v1/dashboard", method: :get)
    end

    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/admin/v1/dashboard", method: :get)
    end
  end
end
