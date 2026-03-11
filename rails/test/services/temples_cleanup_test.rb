require "test_helper"

class TemplesCleanupTest < ActiveSupport::TestCase
  test "cleanup removes temple events services gatherings and related registrations" do
    temple = create_temple(slug: "demo-lotus", name: "Demo Lotus")
    other_temple = create_temple(slug: "other-temple", name: "Other Temple")

    user = User.create!(
      email: "patron@example.com",
      encrypted_password: User.password_hash("Password123!"),
      english_name: "Patron"
    )

    event = temple.temple_events.create!(
      slug: "event-one",
      title: "Event One",
      starts_on: Date.current,
      ends_on: Date.current + 1.day,
      price_cents: 1000,
      currency: "TWD"
    )
    service = temple.temple_services.create!(
      slug: "service-one",
      title: "Service One",
      available_from: Date.current,
      available_until: Date.current + 7.days,
      price_cents: 1500,
      currency: "TWD"
    )
    gathering = temple.temple_gatherings.create!(
      slug: "gathering-one",
      title: "Gathering One",
      starts_on: Date.current,
      ends_on: Date.current,
      price_cents: 0,
      currency: "TWD"
    )

    create_registration(user:, offering: event)
    create_registration(user:, offering: service)
    gathering_registration = create_registration(
      user:,
      offering: gathering,
      total_price_cents: 0,
      unit_price_cents: 0
    )
    create_payment(registration: gathering_registration, amount_cents: 0)

    other_gathering = other_temple.temple_gatherings.create!(
      slug: "other-gathering",
      title: "Other Gathering",
      starts_on: Date.current,
      ends_on: Date.current,
      price_cents: 0,
      currency: "TWD"
    )

    result = Temples::Cleanup.call(slug: temple.slug)

    assert_equal 3, result.registrations
    assert_equal 1, result.events
    assert_equal 1, result.services
    assert_equal 1, result.gatherings

    assert_equal 0, temple.temple_registrations.count
    assert_equal 0, temple.temple_payments.count
    assert_equal 0, temple.temple_events.count
    assert_equal 0, temple.temple_services.count
    assert_equal 0, temple.temple_gatherings.count

    assert_equal 1, other_temple.temple_gatherings.where(id: other_gathering.id).count
  end
end
