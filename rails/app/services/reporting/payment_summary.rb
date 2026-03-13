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

    def completed_amount_cents
      @completed_amount_cents ||= scoped_payments.where(status: TemplePayment::STATUSES[:completed]).sum(:amount_cents)
    end

    def completed_count
      @completed_count ||= scoped_payments.where(status: TemplePayment::STATUSES[:completed]).count
    end

    def pending_count
      @pending_count ||= scoped_payments.where(status: TemplePayment::STATUSES[:pending]).count
    end

    def refunded_count
      @refunded_count ||= scoped_payments.where(status: TemplePayment::STATUSES[:refunded]).count
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
        .group("temple_registrations.registrable_type")
        .group("COALESCE(temple_events.title, temple_services.title, temple_gatherings.title, 'Unassigned')")
        .sum(:amount_cents)

      @totals_by_offering = group_and_format_offering(sums)
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

    def group_and_format_offering(hash)
      hash.sort_by { |(type, title), _| [type.to_s, title.to_s] }.map do |(type, title), cents|
        { label: "#{offering_prefix(type)} · #{title}", amount_cents: cents }
      end
    end

    def offering_prefix(type)
      case type
      when "TempleService"
        "Service"
      when "TempleGathering"
        "Gathering"
      else
        "Event"
      end
    end
  end
end
