require "test_helper"

class TemplePaymentTest < ActiveSupport::TestCase
  test "validates payment method" do
    temple = create_temple
    offering = TempleOffering.create!(temple:, slug: "lamp", title: "Lamp", currency: "TWD", price_cents: 500)
    registration = TempleEventRegistration.create!(
      temple:,
      temple_offering: offering,
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
end
