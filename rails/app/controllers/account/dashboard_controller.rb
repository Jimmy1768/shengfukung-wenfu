module Account
  class DashboardController < BaseController
    def index
      @upcoming_items = [
        { title: "新春點燈", date: "2026/02/01", status: "已報名", description: "請於 08:30 到主殿報到。" },
        { title: "祈福法會", date: "2026/03/15", status: "報名中", description: "線上報名截止 3/05。" }
      ]

      @quick_actions = [
        { label: "更新個人資料", url: account_profile_path },
        { label: "查看活動", url: account_events_path },
        { label: "付款紀錄", url: account_payments_path }
      ]
    end
  end
end
