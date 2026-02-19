require "test_helper"

class TempleOfferingTest < ActiveSupport::TestCase
  test "generates slug when missing" do
    temple = create_temple
    offering = TempleOffering.new(temple:, title: "Lamp Offering", currency: "TWD", price_cents: 1000, starts_on: Date.current, ends_on: Date.current + 1.day)

    assert offering.valid?
    assert offering.slug.present?
  end

  test "enforces unique slug per temple" do
    temple = create_temple
    TempleOffering.create!(temple:, slug: "lamp", title: "Lamp", currency: "TWD", price_cents: 100, starts_on: Date.current, ends_on: Date.current + 1.day)

    duplicate = TempleOffering.new(temple:, slug: "lamp", title: "Another", currency: "TWD", price_cents: 100, starts_on: Date.current, ends_on: Date.current + 1.day)
    assert_not duplicate.valid?
  end

  test "capacity_remaining excludes cancelled registrations" do
    temple = create_temple
    offering = TempleOffering.create!(
      temple:,
      slug: "capacity-test",
      title: "Capacity Test",
      currency: "TWD",
      price_cents: 100,
      available_slots: 2,
      starts_on: Date.current,
      ends_on: Date.current + 1.day
    )
    user = User.create!(
      email: "capacity@example.com",
      english_name: "Capacity User",
      encrypted_password: User.password_hash("Password123!")
    )
    _active = create_registration(user:, offering:)
    create_registration(
      user:,
      offering:,
      reference_code: "REG-CANCEL",
      fulfillment_status: TempleEventRegistration::FULFILLMENT_STATUSES[:cancelled],
      cancelled_at: Time.current
    )

    assert_equal 1, offering.capacity_remaining
  end
end
