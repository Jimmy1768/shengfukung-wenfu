# frozen_string_literal: true

module Admin
  class TempleSwitchesController < BaseController
    def create
      unless allow_temple_switch?
        redirect_back fallback_location: admin_dashboard_path, alert: "Temple switching is limited to owner accounts."
        return
      end

      temple = available_admin_temples.find { |record| record.slug == requested_slug }
      unless temple
        redirect_back fallback_location: admin_dashboard_path, alert: "You do not have access to that temple."
        return
      end

      set_admin_selected_temple_slug(temple.slug)
      @current_temple = temple
      redirect_back fallback_location: admin_dashboard_path, notice: "Now viewing #{temple.name}."
    end

    private

    def requested_slug
      temple_switch_params[:temple_slug].to_s.strip
    end

    def temple_switch_params
      params.require(:temple_switch).permit(:temple_slug)
    end
  end
end
