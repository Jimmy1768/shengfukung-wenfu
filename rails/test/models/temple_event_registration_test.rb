require "test_helper"

class TempleEventRegistrationTest < ActiveSupport::TestCase
  test "backfills totals using offering price" do
    temple = create_temple
    offering = TempleOffering.create!(temple:, slug: "lamp", title: "Lamp", currency: "TWD", price_cents: 500, starts_on: Date.current, ends_on: Date.current + 1.day)
    registration = TempleEventRegistration.create!(
      temple:,
      registrable: offering,
      quantity: 2,
      contact_payload: {},
      logistics_payload: {},
      metadata: {}
    )

    assert_equal 500, registration.unit_price_cents
    assert_equal 1000, registration.total_price_cents
    assert_equal TempleEventRegistration::PAYMENT_STATUSES[:pending], registration.payment_status
    assert registration.expires_at.present?
  end

  test "does not assign expiration for free registrations" do
    temple = create_temple
    offering = TempleOffering.create!(temple:, slug: "free", title: "Free", currency: "TWD", price_cents: 0, starts_on: Date.current, ends_on: Date.current + 1.day)
    registration = TempleEventRegistration.create!(
      temple:,
      registrable: offering,
      quantity: 1,
      contact_payload: {},
      logistics_payload: {},
      metadata: {}
    )

    assert_nil registration.expires_at
  end

  test "mark_paid clears expires_at" do
    temple = create_temple
    offering = TempleOffering.create!(temple:, slug: "paid", title: "Paid", currency: "TWD", price_cents: 500, starts_on: Date.current, ends_on: Date.current + 1.day)
    registration = create_registration(
      user: User.create!(
        email: "paid-clear@example.com",
        english_name: "Paid Clear",
        encrypted_password: User.password_hash("Password123!")
      ),
      offering:
    )
    assert registration.expires_at.present?

    registration.mark_paid!
    registration.reload

    assert_equal TempleEventRegistration::PAYMENT_STATUSES[:paid], registration.payment_status
    assert_nil registration.expires_at
  end

  test "cancel_expired_unpaid cancels only stale unpaid registrations" do
    temple = create_temple
    offering = TempleOffering.create!(temple:, slug: "stale", title: "Stale", currency: "TWD", price_cents: 500, starts_on: Date.current, ends_on: Date.current + 1.day)
    user = User.create!(email: "stale@example.com", english_name: "Stale User", encrypted_password: User.password_hash("Password123!"))
    stale = create_registration(
      user:,
      offering:,
      expires_at: 2.days.ago
    )
    fresh = create_registration(
      user:,
      offering:,
      reference_code: "REG-FRESH",
      expires_at: 2.days.from_now
    )
    paid = create_registration(
      user:,
      offering:,
      reference_code: "REG-PAID"
    )
    create_payment(registration: paid)

    cancelled_count = TempleEventRegistration.cancel_expired_unpaid!(now: Time.current)

    assert_equal 1, cancelled_count
    assert_equal TempleEventRegistration::FULFILLMENT_STATUSES[:cancelled], stale.reload.fulfillment_status
    assert stale.cancelled_at.present?
    assert_nil stale.expires_at
    assert_equal TempleEventRegistration::FULFILLMENT_STATUSES[:open], fresh.reload.fulfillment_status
    assert_equal TempleEventRegistration::FULFILLMENT_STATUSES[:open], paid.reload.fulfillment_status
  end

  test "admin_filtered returns unpaid registrations when requested" do
    temple = create_temple
    offering = TempleOffering.create!(temple:, slug: "lamp", title: "Lamp", currency: "TWD", price_cents: 500, starts_on: Date.current, ends_on: Date.current + 1.day)
    paid = TempleEventRegistration.create!(
      temple:,
      registrable: offering,
      quantity: 1,
      contact_payload: {},
      logistics_payload: {},
      metadata: {},
      payment_status: TempleEventRegistration::PAYMENT_STATUSES[:paid]
    )
    unpaid = TempleEventRegistration.create!(
      temple:,
      registrable: offering,
      quantity: 1,
      contact_payload: {},
      logistics_payload: {},
      metadata: {},
      payment_status: TempleEventRegistration::PAYMENT_STATUSES[:pending]
    )

    scoped = TempleEventRegistration.admin_filtered(status: "unpaid")
      .where(id: [paid.id, unpaid.id])

    assert_equal [unpaid.id], scoped.pluck(:id)
  end

  test "admin_filtered applies fuzzy search across patron data" do
    temple = create_temple
    offering = TempleOffering.create!(temple:, slug: "incense", title: "Incense", currency: "TWD", price_cents: 300, starts_on: Date.current, ends_on: Date.current + 1.day)
    match = TempleEventRegistration.create!(
      temple:,
      registrable: offering,
      quantity: 1,
      contact_payload: { "name" => "Harmony Liu" },
      logistics_payload: {},
      metadata: {},
      reference_code: "REG-SEARCH"
    )
    _other = TempleEventRegistration.create!(
      temple:,
      registrable: offering,
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
