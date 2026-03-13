# frozen_string_literal: true

require "csv"

module Reporting
  class PaymentsCsvExporter
    HEADER = [
      "Processed At",
      "Reference",
      "Patron",
      "Patron Phone",
      "Offering Type",
      "Offering",
      "Registration Period Key",
      "Method",
      "Status",
      "Amount",
      "Currency",
      "Recorded By"
    ].freeze

    def initialize(payments:)
      @payments = payments
    end

    def to_csv
      CSV.generate(headers: true) do |csv|
        csv << HEADER
        payments.find_each(batch_size: 200) do |payment|
          csv << build_row(payment)
        end
      end
    end

    private

    attr_reader :payments

    def build_row(payment)
      registration = payment.offering_registration
      offering_title = registration&.offering&.title
      patron_label = registration&.user&.english_name || registration&.user&.email || payment.user&.english_name || payment.user&.email
      recorded_by = payment.admin_account&.user&.english_name || payment.admin_account&.user&.email || "System"

      [
        (payment.processed_at || payment.created_at)&.iso8601,
        payment.external_reference.presence || registration&.reference_code || payment.id,
        patron_label || "Guest",
        patron_phone_for(payment, registration),
        offering_type_for(registration),
        offering_title || "—",
        registration_period_key_for(registration),
        payment.payment_method,
        payment.status,
        format_amount(payment.amount_cents),
        payment.currency,
        recorded_by
      ]
    end

    def format_amount(cents)
      cents.to_f / 100.0
    end

    def registration_period_key_for(registration)
      metadata_key = registration&.metadata.to_h["registration_period_key"]
      return metadata_key if metadata_key.present?

      offering = registration&.offering
      return unless offering.respond_to?(:registration_period_key)

      offering.registration_period_key
    end

    def patron_phone_for(payment, registration)
      registration&.user&.metadata.to_h["phone"].presence ||
        registration&.contact_payload.to_h["phone"].presence ||
        payment.user&.metadata.to_h["phone"].presence ||
        "—"
    end

    def offering_type_for(registration)
      offering = registration&.offering
      case offering
      when TempleService
        "Service"
      when TempleGathering
        "Gathering"
      when TempleEvent
        "Event"
      else
        "—"
      end
    end
  end
end
