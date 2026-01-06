# frozen_string_literal: true

require "test_helper"
require Rails.root.join("app/services/archives/annual_rollup")

class ArchivesAnnualRollupTest < ActiveSupport::TestCase
  test "returns aggregated totals per year" do
    temple = create_temple
    create_rollup_data(temple:, year: 2023, registrations: 2, certificates: 1, amount_cents: 5000)
    create_rollup_data(temple:, year: 2024, registrations: 1, certificates: 0, amount_cents: 2500)

    rollups = Archives::AnnualRollup.new(temple:).rollups(limit: 5)

    assert_equal 2, rollups.length
    assert_equal 2024, rollups.first[:year]
    assert_equal 2023, rollups.last[:year]
    assert_equal 2, rollups.find { |row| row[:year] == 2023 }[:registrations]
    assert_equal 2, rollups.find { |row| row[:year] == 2023 }[:certificates]
    assert_equal 5000, rollups.find { |row| row[:year] == 2023 }[:payment_total_cents]
  end

  private

  def create_rollup_data(temple:, year:, registrations:, certificates:, amount_cents:)
    offering = temple.temple_offerings.create!(
      slug: "offering-#{year}-#{SecureRandom.hex(1)}",
      title: "Offering #{year}",
      price_cents: amount_cents / [registrations, 1].max,
      currency: "TWD",
      offering_type: "general"
    )

    registrations.times do |index|
      registration = temple.temple_event_registrations.create!(
        temple_offering: offering,
        reference_code: "REG-#{year}-#{index}",
        quantity: 1,
        unit_price_cents: offering.price_cents,
        total_price_cents: offering.price_cents,
        currency: "TWD",
        payment_status: "paid",
        fulfillment_status: "fulfilled",
        certificate_number: certificates.positive? ? "CERT-#{year}-#{index}" : nil,
        created_at: Time.zone.local(year, 2, 1)
      )
      TemplePayment.create!(
        temple_event_registration: registration,
        temple:,
        amount_cents: offering.price_cents,
        currency: "TWD",
        payment_method: TemplePayment::PAYMENT_METHODS[:cash],
        status: TemplePayment::STATUSES[:completed],
        processed_at: Time.zone.local(year, 2, 5)
      )
    end
  end
end
