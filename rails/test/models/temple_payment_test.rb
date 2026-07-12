require "test_helper"

class TemplePaymentTest < ActiveSupport::TestCase
  test "validates payment method" do
    temple = create_temple
    offering = TempleOffering.create!(
      temple:,
      slug: "lamp",
      title: "Lamp",
      currency: "TWD",
      price_cents: 500,
      starts_on: Date.current,
      ends_on: Date.current + 1.day
    )
    registration = TempleEventRegistration.create!(
      temple:,
      registrable: offering,
      quantity: 1,
      contact_payload: {},
      logistics_payload: {},
      metadata: {}
    )

    payment = TemplePayment.new(
      temple:,
      temple_event_registration: registration,
      payment_method: "invalid",
      status: TemplePayment::STATUSES[:pending],
      amount_cents: 500,
      currency: "TWD"
    )

    assert_not payment.valid?
  end

  test "admin_filtered respects date range filtering" do
    temple = create_temple
    offering = TempleOffering.create!(
      temple:,
      slug: "candle",
      title: "Candle",
      currency: "TWD",
      price_cents: 400,
      starts_on: Date.current,
      ends_on: Date.current + 1.day
    )
    recent = TempleEventRegistration.create!(
      temple:,
      registrable: offering,
      quantity: 1,
      contact_payload: {},
      logistics_payload: {},
      metadata: {}
    )
    older = TempleEventRegistration.create!(
      temple:,
      registrable: offering,
      quantity: 1,
      contact_payload: {},
      logistics_payload: {},
      metadata: {}
    )
    old_payment = TemplePayment.create!(
      temple:,
      temple_event_registration: older,
      provider: "demo",
      provider_account: "temple",
      payment_method: TemplePayment::PAYMENT_METHODS[:cash],
      status: TemplePayment::STATUSES[:completed],
      amount_cents: 400,
      currency: "TWD",
      processed_at: 30.days.ago
    )
    recent_payment = TemplePayment.create!(
      temple:,
      temple_event_registration: recent,
      provider: "demo",
      provider_account: "temple",
      payment_method: TemplePayment::PAYMENT_METHODS[:cash],
      status: TemplePayment::STATUSES[:completed],
      amount_cents: 400,
      currency: "TWD",
      processed_at: 2.days.ago
    )

    scoped = TemplePayment.where(id: [old_payment.id, recent_payment.id])
      .merge(
        TemplePayment.admin_filtered(
          start_date: 5.days.ago.to_date.iso8601,
          end_date: Time.zone.today.iso8601
        )
      )

    assert_equal [recent_payment.id], scoped.pluck(:id)
  end
end
