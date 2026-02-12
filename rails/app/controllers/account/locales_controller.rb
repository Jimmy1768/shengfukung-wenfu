module Account
  class LocalesController < BaseController
    skip_before_action :authenticate_user!

    def create
      next_locale = normalize_account_locale(locale_params[:locale])
      session[ACCOUNT_LOCALE_SESSION_KEY] = next_locale
      @current_account_locale = next_locale
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
