# frozen_string_literal: true

module Admin
  class ArchivesController < BaseController
    helper_method :allow_archive_details?, :allow_archive_exports?

    before_action :require_archive_exports!, only: %i[registrations_export payments_export certificates_export]

    def index
      @selected_year = selected_year
      @lookup = Archives::Lookup.new(temple: current_temple, year: @selected_year)
      @available_years = @lookup.available_years
      @annual_rollups = Archives::AnnualRollup.new(temple: current_temple).rollups(limit: 5)
      @summary = build_summary(@lookup)
      if allow_archive_details?
        @registrations = @lookup.registrations.limit(100)
        @payments = @lookup.payments.limit(100)
        @certificates = @lookup.certificates.limit(100)
      else
        @registrations = TempleEventRegistration.none
        @payments = TemplePayment.none
        @certificates = TempleEventRegistration.none
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

    def selected_year
      year = params[:year].presence&.to_i
      return year if year.present? && year > 2000

      Time.zone.today.year
    end

    def lookup
      @lookup ||= Archives::Lookup.new(temple: current_temple, year: selected_year)
    end

    def allow_archive_details?
      current_admin.admin_account.owner_role? || current_admin_permissions&.allow?(:view_financials)
    end

    def allow_archive_exports?
      current_admin.admin_account.owner_role? || current_admin_permissions&.allow?(:export_financials)
    end

    def require_archive_exports!
      return if allow_archive_exports?

      redirect_to admin_archives_path(year: selected_year), alert: "You do not have permission to export archives."
    end

    def build_summary(lookup)
      {
        registrations_count: lookup.registrations.count,
        payments_total_cents: lookup.payments.sum(:amount_cents),
        certificates_count: lookup.certificates.count,
        paid_registrations: lookup.registrations.where(payment_status: TempleEventRegistration::PAYMENT_STATUSES[:paid]).count
      }
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
