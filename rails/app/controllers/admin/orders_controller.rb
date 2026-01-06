# frozen_string_literal: true

module Admin
  class OrdersController < BaseController
    before_action :require_manage_registrations!

    def index
      @registrations = current_temple.temple_event_registrations
        .includes(:user, :temple_offering)
        .order(created_at: :desc)
        .limit(100)
    end

    private

    def require_manage_registrations!
      require_capability!(:manage_registrations)
    end
  end
end
