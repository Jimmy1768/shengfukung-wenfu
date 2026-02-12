module Account
  class DashboardController < BaseController
    def index
      @registrations = current_user.temple_event_registrations
        .includes(:registrable)
        .order(created_at: :desc)
        .limit(3)
      @certificates = current_user.temple_event_registrations
        .with_certificate_number
        .includes(:registrable)
        .order(updated_at: :desc)
        .limit(3)
      @recent_payments = current_user.temple_payments
        .includes(temple_event_registration: :registrable)
        .order(Arel.sql("COALESCE(temple_payments.processed_at, temple_payments.created_at) DESC"))
        .limit(3)
      @quick_actions = [
        { label: I18n.t("account.dashboard.quick_actions.profile"), url: account_profile_path },
        { label: I18n.t("account.dashboard.quick_actions.registrations"), url: account_registrations_path },
        { label: I18n.t("account.dashboard.quick_actions.payments"), url: account_payments_path }
      ]
    end
  end
end
