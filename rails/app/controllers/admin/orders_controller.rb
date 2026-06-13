# frozen_string_literal: true

module Admin
  class OrdersController < BaseController
    before_action :require_manage_registrations!

    def index
      @filters = normalized_filter_params
      scoped = current_temple.temple_event_registrations
        .merge(TempleEventRegistration.admin_filtered(@filters))
      @orders_visible_limit = 50
      unpaid_scope = scoped
        .where.not(payment_status: TempleEventRegistration::PAYMENT_STATUSES[:paid])
      paid_scope = scoped
        .where(payment_status: TempleEventRegistration::PAYMENT_STATUSES[:paid])
      @unpaid_orders_total_count = unpaid_scope.count
      @recent_orders_total_count = paid_scope.count
      @unpaid_orders = unpaid_scope
        .order(created_at: :desc)
        .limit(@orders_visible_limit)
        .to_a
      @recent_orders = paid_scope
        .order(created_at: :desc)
        .limit(@orders_visible_limit)
        .to_a
      @filter_offerings = [
        current_temple.temple_events.order(:title),
        current_temple.temple_services.order(:title),
        current_temple.temple_gatherings.order(:title)
      ].flat_map(&:to_a)
      @filter_payment_methods = TemplePayment::PAYMENT_METHODS.values
      @filter_hidden_fields = filter_hidden_params
    end

    private

    def require_manage_registrations!
      require_capability!(:manage_registrations)
    end

  end
end
