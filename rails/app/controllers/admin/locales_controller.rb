# frozen_string_literal: true

module Admin
  class LocalesController < BaseController
    def create
      next_locale = normalize_admin_locale(locale_params[:locale])
      session[LOCALE_SESSION_KEY] = next_locale
      @current_admin_locale = next_locale
      redirect_back(
        fallback_location: admin_dashboard_path,
        notice: I18n.t("admin.language_selector.flash")
      )
    end

    private

    def locale_params
      params.require(:locale_switch).permit(:locale)
    end
  end
end
