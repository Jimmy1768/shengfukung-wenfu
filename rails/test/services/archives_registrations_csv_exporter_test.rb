# frozen_string_literal: true

require "test_helper"
require Rails.root.join("app/services/archives/registrations_csv_exporter")

class ArchivesRegistrationsCsvExporterTest < ActiveSupport::TestCase
  test "includes registration period key from metadata in csv output" do
    temple = create_temple
    offering = TempleOffering.create!(
      temple: temple,
      slug: "lantern",
      title: "Lantern",
      starts_on: Date.current,
      ends_on: Date.current + 1.day,
      offering_type: "general",
      currency: "TWD",
      price_cents: 600
    )
    registration = TempleEventRegistration.create!(
      temple: temple,
      registrable: offering,
      quantity: 1,
      unit_price_cents: 600,
      total_price_cents: 600,
      currency: "TWD",
      payment_status: TempleEventRegistration::PAYMENT_STATUSES[:pending],
      fulfillment_status: TempleEventRegistration::FULFILLMENT_STATUSES[:open],
      contact_payload: {},
      logistics_payload: {},
      metadata: { "registration_period_key" => "2026-ghost-month" }
    )

    csv = Archives::RegistrationsCsvExporter.new(registrations: TempleEventRegistration.where(id: registration.id)).to_csv

    assert_includes csv, "Registration Period Key"
    assert_includes csv, "2026-ghost-month"
    assert_includes csv, registration.reference_code
  end
end
