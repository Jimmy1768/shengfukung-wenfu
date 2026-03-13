# frozen_string_literal: true

module Admin
  class ArchivesController < BaseController
    helper_method :allow_archive_details?, :allow_archive_exports?, :archive_heading_title, :archive_heading_hint, :archive_month_presets, :archive_export_filter_params

    before_action :require_archive_access!, only: :index
    before_action :require_archive_exports!, only: %i[registrations_export payments_export certificates_export]
    before_action :prepare_archive_context, only: %i[index registrations_export payments_export certificates_export]

    def index
      @filter_hidden_fields = filter_hidden_params
      @filter_offerings = current_temple.temple_events.order(:title).to_a + current_temple.temple_services.order(:title).to_a
      @filter_payment_methods = TemplePayment::PAYMENT_METHODS.values
      @filter_statuses = TemplePayment::STATUSES.values
      @filter_errors = []
      @awaiting_range = @filters[:start_date].blank? && @filters[:end_date].blank? && @resolved_patron.blank?
      if allow_archive_details?
        if archive_range_selected? || @resolved_patron.present?
          scoped_payments = archive_payment_scope
          @archive_summary = build_archive_summary(scoped_payments)
          @archived_payments = scoped_payments.limit(500)
        else
          @archived_payments = TemplePayment.none
          @archive_summary = empty_archive_summary
          if partial_range_selected?
            @filter_errors << "Please select both a start and end date to load archives."
          elsif @filters[:query].present?
            @filter_errors << archive_query_error_message
          end
        end
      else
        @filter_errors = []
        @awaiting_range = true
        @archived_payments = TemplePayment.none
        @archive_summary = empty_archive_summary
      end
    end

    def registrations_export
      exporter = Archives::RegistrationsCsvExporter.new(registrations: archive_registration_scope)
      log_export!("registrations")
      send_archive(exporter.to_csv, "registrations")
    end

    def payments_export
      exporter = Reporting::PaymentsCsvExporter.new(payments: archive_payment_scope)
      log_export!("payments")
      send_archive(exporter.to_csv, "payments")
    end

    def certificates_export
      exporter = Archives::RegistrationsCsvExporter.new(
        registrations: archive_registration_scope.with_certificate_number,
        include_certificate: true
      )
      log_export!("certificates")
      send_archive(exporter.to_csv, "certificates")
    end

    private

    def archive_range_selected?
      @filters[:start_date].present? && @filters[:end_date].present?
    end

    def partial_range_selected?
      @filters[:start_date].present? ^ @filters[:end_date].present?
    end

    def archive_payment_scope
      scope = current_temple.temple_payments
        .merge(TemplePayment.admin_filtered(@filters))
        .order(Arel.sql("COALESCE(temple_payments.processed_at, temple_payments.created_at) DESC"))
      return scope unless @resolved_patron.present? && !archive_range_selected?

      scope.where(user: @resolved_patron)
    end

    def archive_registration_scope
      scope = current_temple.temple_event_registrations
        .merge(TempleRegistration.admin_filtered(@filters))
        .order(created_at: :desc)
      return scope unless @resolved_patron.present? && !archive_range_selected?

      scope.where(user: @resolved_patron)
    end

    def archive_heading_title
      if @resolved_patron.present? && !archive_range_selected?
        "Archive history for #{@resolved_patron.english_name.presence || @resolved_patron.email}"
      else
        I18n.t("admin.archives.payments.range_heading", start: @filters[:start_date], end: @filters[:end_date])
      end
    end

    def archive_heading_hint
      if @resolved_patron.present? && !archive_range_selected?
        "Showing all archived payments for the matched patron across all dates."
      else
        I18n.t("admin.archives.payments.range_hint")
      end
    end

    def archive_month_presets
      [
        {
          key: "this_month",
          label: I18n.t("admin.archives.payments.presets.this_month"),
          filters: preset_filters_for(Time.zone.today.beginning_of_month.to_date, Time.zone.today.end_of_month.to_date)
        },
        {
          key: "last_month",
          label: I18n.t("admin.archives.payments.presets.last_month"),
          filters: preset_filters_for(1.month.ago.beginning_of_month.to_date, 1.month.ago.end_of_month.to_date)
        }
      ]
    end

    def archive_export_filter_params
      { filter: @filters.compact_blank }
    end

    def allow_archive_details?
      current_admin.admin_account.owner_role? || current_admin_permissions&.allow?(:view_financials)
    end

    def selected_year
      year = params[:year].presence&.to_i
      return year if year.present? && year > 2000

      Time.zone.today.year
    end

    def lookup
      @lookup ||= Archives::Lookup.new(temple: current_temple, year: selected_year)
    end

    def allow_archive_exports?
      current_admin.admin_account.owner_role? || current_admin_permissions&.allow?(:export_financials)
    end

    def allow_archive_access?
      allow_archive_details? || allow_archive_exports?
    end

    def require_archive_access!
      return if allow_archive_access?

      redirect_to admin_dashboard_path, alert: "You do not have permission to access archives."
    end

    def require_archive_exports!
      return if allow_archive_exports?

      redirect_to admin_archives_path(year: selected_year), alert: "You do not have permission to export archives."
    end

    def send_archive(payload, label)
      filename = [
        "archives",
        label,
        archive_filename_scope,
        Time.current.strftime("%Y%m%d")
      ].compact.join("-") + ".csv"
      send_data payload, filename:, type: "text/csv"
    end

    def log_export!(kind)
      SystemAuditLogger.log!(
        action: "admin.archives.export",
        admin: current_admin,
        temple: current_temple,
        metadata: {
          export_kind: kind,
          year: selected_year,
          filters: @filters.compact_blank,
          resolved_patron_id: @resolved_patron&.id
        }
      )
    end

    def resolve_archive_patron
      return if archive_range_selected?
      return if @filters[:query].blank?

      matches = current_temple.temple_event_registrations
        .joins(:user)
        .merge(archive_patron_query_scope(@filters[:query]))
        .distinct
        .limit(2)
        .map(&:user)
        .uniq { |user| user.id }

      return matches.first if matches.one?

      nil
    end

    def archive_patron_query_scope(query)
      sanitized = ActiveRecord::Base.sanitize_sql_like(query.to_s.strip)
      User.where(
        "users.english_name ILIKE :query OR users.email ILIKE :query OR COALESCE(users.metadata ->> 'phone', '') ILIKE :query",
        query: "%#{sanitized}%"
      )
    end

    def archive_query_error_message
      matches = current_temple.temple_event_registrations
        .joins(:user)
        .merge(archive_patron_query_scope(@filters[:query]))
        .distinct
        .limit(2)
        .count

      if matches.zero?
        "No matching patron was found. Add a date range or refine the patron search."
      else
        "Multiple patrons matched that search. Refine the patron search or add a date range."
      end
    end

    def preset_filters_for(start_date, end_date)
      @filters.slice(:query, :offering_kind, :offering_reference, :payment_method).merge(
        start_date: start_date.to_s,
        end_date: end_date.to_s
      )
    end

    def build_archive_summary(scope)
      {
        total_amount_cents: scope.sum(:amount_cents),
        payment_count: scope.count,
        completed_count: scope.where(status: TemplePayment::STATUSES[:completed]).count,
        refunded_count: scope.where(status: TemplePayment::STATUSES[:refunded]).count
      }
    end

    def empty_archive_summary
      {
        total_amount_cents: 0,
        payment_count: 0,
        completed_count: 0,
        refunded_count: 0
      }
    end

    def prepare_archive_context
      @filters = normalized_filter_params
      @resolved_patron = resolve_archive_patron
    end

    def archive_filename_scope
      if @resolved_patron.present? && !archive_range_selected?
        patron_label = @resolved_patron.english_name.presence
        parameterized = parameterize_filename_segment(patron_label)
        parameterized == "patron-history" ? parameterize_filename_segment(@resolved_patron.email) : parameterized
      elsif archive_range_selected?
        "#{@filters[:start_date]}-to-#{@filters[:end_date]}"
      else
        selected_year.to_s
      end
    end

    def parameterize_filename_segment(value)
      value.to_s.parameterize(separator: "-").presence || "patron-history"
    end
  end
end
