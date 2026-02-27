# frozen_string_literal: true

module Account
  class ThemesController < BaseController
    skip_before_action :authenticate_user!

    def create
      next_mode = Themes::Policy.resolve_mode_id(
        surface: :account,
        requested: theme_params[:mode_key]
      )

      cookies[Themes::Policy.cookie_key(:account)] = {
        value: next_mode,
        expires: Themes::Policy::COOKIE_EXPIRY.from_now,
        httponly: false
      }
      persist_account_display_mode!(next_mode)

      redirect_back(
        fallback_location: account_login_path,
        notice: I18n.t("account.theme_selector.flash", locale: current_account_locale)
      )
    end

    private

    def theme_params
      params.require(:theme_switch).permit(:mode_key)
    end

    def persist_account_display_mode!(mode_id)
      return unless current_user.present?

      preference = UserPreference.for_user(current_user)
      preference.set_display_mode(:account, mode_id)
      preference.save!
    end
  end
end
