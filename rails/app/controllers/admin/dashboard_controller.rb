module Admin
  class DashboardController < BaseController
    def index
      @metrics = [
        { label: I18n.t("admin.dashboard.metrics.entries.active_members"), value: User.count },
        { label: I18n.t("admin.dashboard.metrics.entries.pending_invites"), value: 3 },
        { label: I18n.t("admin.dashboard.metrics.entries.revenue_placeholder"), value: "$12.3K" }
      ]
      @next_steps = build_next_steps
    end

    private

    def build_next_steps
      steps = []
      steps << { label: t("admin.dashboard.next_steps.fill_profile"), url: admin_temple_profile_path } if profile_incomplete?
      steps << { label: t("admin.dashboard.next_steps.setup_offerings"), url: new_admin_offering_path } if missing_offering_templates?
      if owner_account?
        steps << { label: t("admin.dashboard.next_steps.promote_admin_from_patron"), url: admin_patrons_path }
        steps << { label: t("admin.dashboard.next_steps.manage_permissions"), url: admin_permissions_path }
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
      current_temple.present? && !current_temple.temple_offerings.exists?
    end
  end
end
