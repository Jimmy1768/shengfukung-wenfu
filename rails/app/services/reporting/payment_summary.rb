# frozen_string_literal: true

module Reporting
  class PaymentSummary
    def initialize(payments:)
      @payments = payments
    end

    def total_amount_cents
      @total_amount_cents ||= scoped_payments.sum(:amount_cents)
    end

    def total_count
      @total_count ||= scoped_payments.count
    end

    def totals_by_method
      @totals_by_method ||= group_and_format(scoped_payments.group(:payment_method).sum(:amount_cents))
    end

    def totals_by_offering
      return @totals_by_offering if defined?(@totals_by_offering)

      sums = scoped_payments
        .joins(:temple_registration)
        .joins("LEFT JOIN temple_events ON temple_events.id = temple_registrations.registrable_id AND temple_registrations.registrable_type = 'TempleEvent'")
        .joins("LEFT JOIN temple_services ON temple_services.id = temple_registrations.registrable_id AND temple_registrations.registrable_type = 'TempleService'")
        .joins("LEFT JOIN temple_gatherings ON temple_gatherings.id = temple_registrations.registrable_id AND temple_registrations.registrable_type = 'TempleGathering'")
        .group("COALESCE(temple_events.title, temple_services.title, temple_gatherings.title, 'Unassigned')")
        .sum(:amount_cents)

      @totals_by_offering = group_and_format(sums)
    end

    def totals_by_date
      return @totals_by_date if defined?(@totals_by_date)

      sums = scoped_payments
        .group("DATE(COALESCE(temple_payments.processed_at, temple_payments.created_at))")
        .sum(:amount_cents)

      formatted = sums.transform_keys do |date|
        date.is_a?(Date) ? date.strftime("%Y-%m-%d") : date.to_s
      end
      @totals_by_date = group_and_format(formatted)
    end

    private

    attr_reader :payments

    def scoped_payments
      payments
    end

    def group_and_format(hash)
      hash.sort_by { |key, _| key.to_s }.map do |key, cents|
        { label: key.to_s, amount_cents: cents }
      end
    end
  end
end
