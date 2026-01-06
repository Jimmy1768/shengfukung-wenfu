module Account
  class DashboardController < BaseController
    def index
      @registrations = current_user.temple_event_registrations
        .includes(:temple_offering)
        .order(created_at: :desc)
        .limit(3)
      @certificates = current_user.temple_event_registrations
        .where.not(certificate_number: [nil, ""])
        .includes(:temple_offering)
        .order(updated_at: :desc)
        .limit(3)
      @recent_payments = current_user.temple_payments
        .includes(temple_event_registration: :temple_offering)
        .order(Arel.sql("COALESCE(temple_payments.processed_at, temple_payments.created_at) DESC"))
        .limit(3)
      @quick_actions = [
        { label: "更新個人資料", url: account_profile_path },
        { label: "查看報名", url: account_registrations_path },
        { label: "付款紀錄", url: account_payments_path }
      ]
    end
  end
end
