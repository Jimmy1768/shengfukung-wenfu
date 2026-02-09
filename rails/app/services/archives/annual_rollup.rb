# frozen_string_literal: true

module Archives
  class AnnualRollup
    attr_reader :temple

    def initialize(temple:)
      @temple = temple
    end

    def rollups(limit: 5)
      years = all_years.last(limit).reverse
      years.map do |year|
        {
          year: year,
          registrations: registration_counts[year] || 0,
          certificates: certificate_counts[year] || 0,
          payment_total_cents: payment_totals[year] || 0
        }
      end
    end

    private

    def all_years
      @all_years ||= begin
        aggregated_years = registration_counts.keys + payment_totals.keys + certificate_counts.keys
        sorted = aggregated_years.compact.uniq.sort
        sorted.empty? ? [Time.zone.today.year] : sorted
      end
    end

    def registration_counts
      @registration_counts ||= grouped_year_counts(temple.temple_event_registrations)
    end

    def certificate_counts
      @certificate_counts ||= grouped_year_counts(
        temple.temple_event_registrations.with_certificate_number
      )
    end

    def payment_totals
      return @payment_totals if defined?(@payment_totals)

      sums = temple.temple_payments
        .group(year_sql("COALESCE(temple_payments.processed_at, temple_payments.created_at)"))
        .sum(:amount_cents)
      @payment_totals = normalize_keys(sums)
    end

    def grouped_year_counts(scope)
      counts = scope.group(year_sql("created_at")).count
      normalize_keys(counts)
    end

    def year_sql(column)
      Arel.sql("DATE_PART('year', #{column})::int")
    end

    def normalize_keys(hash)
      hash.transform_keys { |key| key.to_i }
    end
  end
end
