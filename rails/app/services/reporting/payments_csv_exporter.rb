# frozen_string_literal: true

require "csv"

module Reporting
  class PaymentsCsvExporter
    HEADER = [
      "Reference",
      "Offering",
      "Registration Period Key",
      "Patron",
      "Method",
      "Status",
      "Amount",
      "Currency",
      "Processed At",
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
        payment.external_reference.presence || registration&.reference_code || payment.id,
        offering_title || "—",
        registration_period_key_for(registration),
        patron_label || "Guest",
        payment.payment_method,
        payment.status,
        format_amount(payment.amount_cents),
        payment.currency,
        (payment.processed_at || payment.created_at)&.iso8601,
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
  end
end
