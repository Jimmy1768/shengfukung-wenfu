module Account
  class LocalesController < BaseController
    skip_before_action :authenticate_user!

    def create
      next_locale = persist_account_locale!(locale_params[:locale])
      @current_account_locale = next_locale

      if current_user
        preference = UserPreference.for_user(current_user)
        preference.update!(locale: next_locale.to_s)
      end

      redirect_back(
        fallback_location: account_login_path,
        notice: I18n.t("account.language_selector.flash", locale: next_locale)
      )
    end

    private

    def locale_params
      params.require(:locale_switch).permit(:locale)
    end
  end
end
