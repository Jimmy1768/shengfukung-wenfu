module Admin
  class DashboardController < BaseController
    def index
      @metrics = [
        { label: I18n.t("admin.dashboard.metrics.entries.active_members"), value: User.count },
        { label: I18n.t("admin.dashboard.metrics.entries.pending_invites"), value: 3 },
        { label: I18n.t("admin.dashboard.metrics.entries.revenue_placeholder"), value: "$12.3K" }
      ]
    end
  end
end
