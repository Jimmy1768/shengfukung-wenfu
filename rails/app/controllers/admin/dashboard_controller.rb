module Admin
  class DashboardController < BaseController
    def index
      registrations = current_temple.temple_event_registrations
      open_status = TempleRegistration::FULFILLMENT_STATUSES[:open]
      month_start = Time.zone.now.beginning_of_month
      now = Time.zone.now
      hold_warning_window_end = now + 24.hours

      new_patrons_month_count = registrations
        .where.not(user_id: nil)
        .group(:user_id)
        .having("MIN(temple_registrations.created_at) >= ?", month_start)
        .count
        .size
      pending_registrations_count = registrations.where(fulfillment_status: open_status).count
      unpaid_registrations_count = registrations
        .where(fulfillment_status: open_status)
        .where("total_price_cents > 0")
        .where.not(payment_status: TempleRegistration::PAYMENT_STATUSES[:paid])
        .count
      expiring_unpaid_holds_count = registrations
        .where(fulfillment_status: open_status, payment_status: TempleRegistration::PAYMENT_STATUSES[:pending])
        .where("total_price_cents > 0")
        .where.not(expires_at: nil)
        .where("temple_registrations.expires_at > ? AND temple_registrations.expires_at <= ?", now, hold_warning_window_end)
        .count
      open_assistance_requests = current_temple.temple_assistance_requests
        .open_requests
        .includes(:user, :temple_registration)
        .recent_first
      open_assistance_requests_count = open_assistance_requests.count
      month_revenue_cents = current_temple.temple_payments
        .completed
        .where("temple_payments.created_at >= ?", month_start)
        .sum(:amount_cents)

      @metrics = [
        { label: I18n.t("admin.dashboard.metrics.entries.new_patrons_mtd"), value: new_patrons_month_count },
        { label: I18n.t("admin.dashboard.metrics.entries.pending_registrations"), value: pending_registrations_count },
        { label: I18n.t("admin.dashboard.metrics.entries.unpaid_registrations"), value: unpaid_registrations_count },
        { label: I18n.t("admin.dashboard.metrics.entries.revenue_mtd"), value: Currency::Symbols.format_amount(month_revenue_cents, "TWD") }
      ]
      @queue_metrics = [
        { label: I18n.t("admin.dashboard.metrics.entries.expiring_unpaid_holds_24h"), value: expiring_unpaid_holds_count },
        { label: I18n.t("admin.dashboard.metrics.entries.open_assistance_requests"), value: open_assistance_requests_count }
      ].select { |metric| metric[:value].to_i.positive? }
      @open_assistance_requests = open_assistance_requests.limit(5)
      @next_steps = build_next_steps
    end

    private

    def build_next_steps
      steps = []
      steps << { label: t("admin.dashboard.next_steps.fill_profile"), url: admin_temple_profile_path } if profile_incomplete?
      steps << { label: t("admin.dashboard.next_steps.setup_offerings"), url: new_admin_event_path } if missing_offering_templates?
      if owner_account?
        steps << { label: t("admin.dashboard.next_steps.promote_admin_from_patron"), url: admin_patrons_path } if needs_admin_promotion?
        steps << { label: t("admin.dashboard.next_steps.manage_permissions"), url: admin_permissions_path } if should_review_permissions?
      end
      steps
    end

    def owner_account?
      current_admin&.admin_account&.owner_role?
    end

    def profile_incomplete?
      current_temple.present? && !current_temple.profile_complete?
    end

    def missing_offering_templates?
      return true unless current_temple.present?
      !current_temple.temple_events.exists? && !current_temple.temple_services.exists?
    end

    def needs_admin_promotion?
      current_temple.present? && !staff_admins_present?
    end

    def should_review_permissions?
      current_temple.present? && staff_admins_present? && !permissions_reviewed?
    end

    def staff_admins_present?
      return false unless current_temple.present?

      @staff_admins_present ||= current_temple.admin_accounts.staff_role.exists?
    end

    def permissions_reviewed?
      current_admin.admin_account.metadata["permissions_reviewed"].present?
    end
  end
end
