# frozen_string_literal: true

require "csv"

module Archives
  class RegistrationsCsvExporter
    REGISTRATION_HEADER = [
      "Created At",
      "Reference",
      "Offering",
      "Registration Period Key",
      "Patron",
      "Quantity",
      "Total Amount",
      "Currency",
      "Payment Status",
      "Fulfillment Status"
    ].freeze
    CERTIFICATE_HEADER = REGISTRATION_HEADER + ["Certificate Number"]

    def initialize(registrations:, include_certificate: false)
      @registrations = registrations
      @include_certificate = include_certificate
    end

    def to_csv
      CSV.generate(headers: true) do |csv|
        csv << header
        registrations.find_each(batch_size: 200) do |registration|
          csv << build_row(registration)
        end
      end
    end

    private

    attr_reader :registrations

    def include_certificate?
      @include_certificate
    end

    def header
      include_certificate? ? CERTIFICATE_HEADER : REGISTRATION_HEADER
    end

    def build_row(registration)
      offering_title = registration.offering&.title || "—"
      patron_label = registration.user&.english_name || registration.user&.email || registration.contact_payload["name"] || "Guest"
      row = [
        registration.created_at.iso8601,
        registration.reference_code,
        offering_title,
        registration_period_key_for(registration),
        patron_label,
        registration.quantity,
        format_amount(registration.total_price_cents),
        registration.currency,
        registration.payment_status,
        registration.fulfillment_status
      ]
      row << registration.certificate_number if include_certificate?
      row
    end

    def format_amount(cents)
      cents.to_f / 100.0
    end

    def registration_period_key_for(registration)
      metadata_key = registration.metadata.to_h["registration_period_key"]
      return metadata_key if metadata_key.present?

      offering = registration.offering
      return unless offering.respond_to?(:registration_period_key)

      offering.registration_period_key
    end
  end
end
