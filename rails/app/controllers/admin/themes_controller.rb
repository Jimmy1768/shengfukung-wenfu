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
      persist_admin_display_mode!(next_mode)

      redirect_back(
        fallback_location: admin_dashboard_path,
        notice: I18n.t("admin.theme_selector.flash", locale: current_admin_locale)
      )
    end

    private

    def theme_params
      params.require(:theme_switch).permit(:mode_key)
    end

    def persist_admin_display_mode!(mode_id)
      return unless current_admin.present?

      preference = UserPreference.for_user(current_admin)
      preference.set_display_mode(:admin, mode_id)
      preference.save!
    end
  end
end
