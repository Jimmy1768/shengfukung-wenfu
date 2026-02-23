# frozen_string_literal: true

module Admin
  class ThemesController < BaseController
    def create
      next_mode = Themes::Policy.resolve_mode_id(
        surface: :admin,
        requested: theme_params[:mode_key]
      )

      cookies[Themes::Policy.cookie_key(:admin)] = {
        value: next_mode,
        expires: Themes::Policy::COOKIE_EXPIRY.from_now,
        httponly: false
      }

      redirect_back(
        fallback_location: admin_dashboard_path,
        notice: I18n.t("admin.theme_selector.flash", locale: current_admin_locale)
      )
    end

    private

    def theme_params
      params.require(:theme_switch).permit(:mode_key)
    end
  end
end
