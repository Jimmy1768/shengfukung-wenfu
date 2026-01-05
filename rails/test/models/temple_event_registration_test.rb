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
end
