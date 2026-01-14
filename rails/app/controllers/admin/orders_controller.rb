# frozen_string_literal: true

module Admin
  class OrdersController < BaseController
    before_action :require_manage_registrations!

    def index
      @filters = normalized_filter_params
      scoped = current_temple.temple_event_registrations
        .merge(TempleEventRegistration.admin_filtered(@filters))
      @unpaid_orders = scoped
        .where.not(payment_status: TempleEventRegistration::PAYMENT_STATUSES[:paid])
        .order(created_at: :desc)
        .limit(50)
      @recent_orders = scoped
        .where(payment_status: TempleEventRegistration::PAYMENT_STATUSES[:paid])
        .order(created_at: :desc)
        .limit(50)
      @filter_offerings = current_temple.temple_offerings.order(:title)
      @filter_payment_methods = TemplePayment::PAYMENT_METHODS.values
      @filter_hidden_fields = filter_hidden_params
    end

    private

    def require_manage_registrations!
      require_capability!(:manage_registrations)
    end

  end
end
