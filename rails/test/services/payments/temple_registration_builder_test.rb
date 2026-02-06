require "test_helper"

module Payments
  class TempleRegistrationBuilderTest < ActiveSupport::TestCase
    test "creates registration with defaults" do
      temple = create_temple
      offering = TempleOffering.create!(temple:, slug: "lamp", title: "Lamp", currency: "TWD", price_cents: 400)
      admin = create_admin_user(temple:)

      builder = TempleRegistrationBuilder.new(
        temple:,
        offering:,
        admin_user: admin,
        attributes: { quantity: 2 }
      )

      registration = builder.create

      assert registration.persisted?
      assert_equal 800, registration.total_price_cents
      assert_equal offering.slug, registration.event_slug
    end
  end
end
