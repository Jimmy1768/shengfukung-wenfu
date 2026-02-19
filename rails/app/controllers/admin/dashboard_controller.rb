module Admin
  class DashboardController < BaseController
    def index
      members_count = current_temple.temple_event_registrations.where.not(user_id: nil).distinct.count(:user_id)
      pending_admin_invites_count = current_temple.admin_temple_memberships
        .joins(:admin_account)
        .where(admins: { active: false })
        .count
      total_revenue_cents = current_temple.temple_payments.completed.sum(:amount_cents)

      @metrics = [
        { label: I18n.t("admin.dashboard.metrics.entries.active_members"), value: members_count },
        { label: I18n.t("admin.dashboard.metrics.entries.pending_invites"), value: pending_admin_invites_count },
        { label: I18n.t("admin.dashboard.metrics.entries.revenue"), value: Currency::Symbols.format_amount(total_revenue_cents, "TWD") }
      ]
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
