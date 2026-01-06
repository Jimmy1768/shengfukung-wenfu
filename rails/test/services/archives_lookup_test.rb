# frozen_string_literal: true

require "test_helper"
require Rails.root.join("app/services/archives/lookup")

class ArchivesLookupTest < ActiveSupport::TestCase
  test "scopes registrations and payments to the selected year" do
    temple = create_temple
    current_year = Time.zone.today.year
    last_year = current_year - 1
    create_registration_for_year(temple:, year: current_year)
    create_registration_for_year(temple:, year: current_year)
    create_registration_for_year(temple:, year: last_year)

    lookup = Archives::Lookup.new(temple:, year: current_year)

    assert_equal 2, lookup.registrations.count
    assert_equal 2, lookup.payments.count
    assert_equal 0, lookup.certificates.count

    lookup_previous = Archives::Lookup.new(temple:, year: last_year)
    assert_equal 1, lookup_previous.registrations.count
  end

  private

  def create_registration_for_year(temple:, year:)
    offering = temple.temple_offerings.create!(
      slug: "offering-#{SecureRandom.hex(2)}",
      title: "Offering #{year}",
      price_cents: 1000,
      currency: "TWD",
      offering_type: "general"
    )
    registration = temple.temple_event_registrations.create!(
      temple_offering: offering,
      reference_code: "REG-#{SecureRandom.hex(2)}",
      quantity: 1,
      unit_price_cents: 1000,
      total_price_cents: 1000,
      currency: "TWD",
      payment_status: "paid",
      fulfillment_status: "fulfilled",
      created_at: Time.zone.local(year, 3, 15)
    )
    TemplePayment.create!(
      temple_event_registration: registration,
      temple:,
      amount_cents: 1000,
      currency: "TWD",
      payment_method: TemplePayment::PAYMENT_METHODS[:cash],
      status: TemplePayment::STATUSES[:completed],
      processed_at: Time.zone.local(year, 3, 20)
    )
    registration
  end
end
