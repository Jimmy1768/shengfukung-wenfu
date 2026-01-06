# frozen_string_literal: true

module Archives
  class Lookup
    attr_reader :temple, :year

    def initialize(temple:, year: Time.zone.today.year)
      @temple = temple
      @year = (year.presence || Time.zone.today.year).to_i
    end

    def registrations
      @registrations ||= temple.temple_event_registrations
        .includes(:temple_offering, :user)
        .where(created_at: year_range)
        .order(created_at: :desc)
    end

    def payments
      @payments ||= temple.temple_payments
        .includes(:temple_event_registration, :user, admin_account: :user)
        .where(date_clause, start_time: year_range.begin, end_time: year_range.end)
        .order(Arel.sql("COALESCE(temple_payments.processed_at, temple_payments.created_at) DESC"))
    end

    def certificates
      @certificates ||= registrations.where.not(certificate_number: [nil, ""])
    end

    def available_years
      return @available_years if defined?(@available_years)

      years = []
      years += temple.temple_event_registrations.distinct.pluck(
        Arel.sql("DATE_PART('year', temple_event_registrations.created_at)::int")
      )
      years += temple.temple_payments.distinct.pluck(
        Arel.sql("DATE_PART('year', COALESCE(temple_payments.processed_at, temple_payments.created_at))::int")
      )
      years = years.compact.uniq.sort.reverse
      years = [Time.zone.today.year] if years.empty?
      @available_years = years
    end

    def year_range
      return @year_range if defined?(@year_range)

      start_time = Time.zone.local(year, 1, 1).beginning_of_year
      @year_range = start_time..start_time.end_of_year
    rescue ArgumentError
      fallback_year = Time.zone.today.year
      @year_range = Time.zone.local(fallback_year, 1, 1).beginning_of_year..Time.zone.local(fallback_year, 12, 31).end_of_day
    end

    private

    def date_clause
      Arel.sql("(COALESCE(temple_payments.processed_at, temple_payments.created_at) BETWEEN :start_time AND :end_time)")
    end
  end
end
