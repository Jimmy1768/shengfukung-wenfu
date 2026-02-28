# frozen_string_literal: true

module Admin
  class ArchivesController < BaseController
    helper_method :allow_archive_details?, :allow_archive_exports?

    before_action :require_archive_access!, only: :index
    before_action :require_archive_exports!, only: %i[registrations_export payments_export certificates_export]

    def index
      @filters = normalized_filter_params
      @filter_hidden_fields = filter_hidden_params
      @filter_offerings = current_temple.temple_events.order(:title).to_a + current_temple.temple_services.order(:title).to_a
      @filter_payment_methods = TemplePayment::PAYMENT_METHODS.values
      @filter_errors = []
      @awaiting_range = @filters[:start_date].blank? && @filters[:end_date].blank?
      if allow_archive_details?
        if archive_range_selected?
          @archived_payments = archive_payment_scope.limit(500)
        else
          @archived_payments = TemplePayment.none
          @filter_errors << "Please select both a start and end date to load archives." if partial_range_selected?
        end
      else
        @filter_errors = []
        @awaiting_range = true
        @archived_payments = TemplePayment.none
      end
    end

    def registrations_export
      exporter = Archives::RegistrationsCsvExporter.new(registrations: lookup.registrations)
      log_export!("registrations")
      send_archive(exporter.to_csv, "registrations")
    end

    def payments_export
      exporter = Reporting::PaymentsCsvExporter.new(payments: lookup.payments)
      log_export!("payments")
      send_archive(exporter.to_csv, "payments")
    end

    def certificates_export
      exporter = Archives::RegistrationsCsvExporter.new(registrations: lookup.certificates, include_certificate: true)
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
      current_temple.temple_payments
        .merge(TemplePayment.admin_filtered(@filters))
        .order(Arel.sql("COALESCE(temple_payments.processed_at, temple_payments.created_at) DESC"))
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
      filename = "archives-#{label}-#{selected_year}-#{Time.current.strftime('%Y%m%d')}.csv"
      send_data payload, filename:, type: "text/csv"
    end

    def log_export!(kind)
      SystemAuditLogger.log!(
        action: "admin.archives.export",
        admin: current_admin,
        temple: current_temple,
        metadata: { export_kind: kind, year: selected_year }
      )
    end
  end
end
