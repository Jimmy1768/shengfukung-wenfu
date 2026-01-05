require "test_helper"

class TempleOfferingTest < ActiveSupport::TestCase
  test "generates slug when missing" do
    temple = create_temple
    offering = TempleOffering.new(temple:, title: "Lamp Offering", currency: "TWD", price_cents: 1000)

    assert offering.valid?
    assert offering.slug.present?
  end

  test "enforces unique slug per temple" do
    temple = create_temple
    TempleOffering.create!(temple:, slug: "lamp", title: "Lamp", currency: "TWD", price_cents: 100)

    duplicate = TempleOffering.new(temple:, slug: "lamp", title: "Another", currency: "TWD", price_cents: 100)
    assert_not duplicate.valid?
  end
end
