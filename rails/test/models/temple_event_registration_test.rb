require "test_helper"

class TempleEventRegistrationTest < ActiveSupport::TestCase
  test "backfills totals using offering price" do
    temple = create_temple
    offering = TempleOffering.create!(temple:, slug: "lamp", title: "Lamp", currency: "TWD", price_cents: 500)
    registration = TempleEventRegistration.create!(
      temple:,
      temple_offering: offering,
      quantity: 2,
      contact_payload: {},
      logistics_payload: {},
      metadata: {}
    )

    assert_equal 500, registration.unit_price_cents
    assert_equal 1000, registration.total_price_cents
    assert_equal TempleEventRegistration::PAYMENT_STATUSES[:pending], registration.payment_status
  end

  test "admin_filtered returns unpaid registrations when requested" do
    temple = create_temple
    offering = TempleOffering.create!(temple:, slug: "lamp", title: "Lamp", currency: "TWD", price_cents: 500)
    paid = TempleEventRegistration.create!(
      temple:,
      temple_offering: offering,
      quantity: 1,
      contact_payload: {},
      logistics_payload: {},
      metadata: {},
      payment_status: TempleEventRegistration::PAYMENT_STATUSES[:paid]
    )
    unpaid = TempleEventRegistration.create!(
      temple:,
      temple_offering: offering,
      quantity: 1,
      contact_payload: {},
      logistics_payload: {},
      metadata: {},
      payment_status: TempleEventRegistration::PAYMENT_STATUSES[:pending]
    )

    scoped = TempleEventRegistration.where(id: [paid.id, unpaid.id])
      .merge(TempleEventRegistration.admin_filtered(status: "unpaid"))

    assert_equal [unpaid.id], scoped.pluck(:id)
  end

  test "admin_filtered applies fuzzy search across patron data" do
    temple = create_temple
    offering = TempleOffering.create!(temple:, slug: "incense", title: "Incense", currency: "TWD", price_cents: 300)
    match = TempleEventRegistration.create!(
      temple:,
      temple_offering: offering,
      quantity: 1,
      contact_payload: { "name" => "Harmony Liu" },
      logistics_payload: {},
      metadata: {},
      reference_code: "REG-SEARCH"
    )
    _other = TempleEventRegistration.create!(
      temple:,
      temple_offering: offering,
      quantity: 1,
      contact_payload: { "name" => "Other Patron" },
      logistics_payload: {},
      metadata: {}
    )

    scoped = TempleEventRegistration.where(id: [match.id, _other.id])
      .merge(TempleEventRegistration.admin_filtered(query: "harm"))

    assert_includes scoped, match
    assert_equal 1, scoped.count
  end
end
