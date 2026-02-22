module Demo
  class BaseController < ActionController::Base
    layout "demo_admin"
    protect_from_forgery with: :exception

    helper Themes::PaletteResolver
    helper Forms::LayoutHelper
    helper_method :current_user,
      :theme_palette,
      :admin_signed_in?,
      :safe_locale_param,
      :active_locale_entry,
      :available_locale_entries

    before_action :set_locale
    before_action :hydrate_theme
    before_action :ensure_admin!

    private

    def set_locale
      entry = AppConstants::Locales.find(safe_locale_param)
      @active_locale_entry = entry
      locale_key = entry[:locale_key].presence || I18n.default_locale
      I18n.locale = locale_key.to_sym
    end

    def hydrate_theme
      @active_theme_key = params[:theme].presence || Themes::DEFAULT_KEY
      @theme_palette = Themes.for(@active_theme_key)
    end

    def theme_palette
      @theme_palette || super
    end

    def ensure_admin!
      return if admin_scope_active?

      redirect_to marketing_admin_login_path(locale: params[:locale], theme: params[:theme]),
        alert: I18n.t("demo_admin.console.alerts.sign_in_required")
    end

    def admin_signed_in?
      admin_scope_active?
    end

    def admin_scope_active?
      current_user&.admin_account&.active?
    end

    def current_user
      return @current_user if defined?(@current_user)

      user_id = session[demo_session_key]
      @current_user =
        if user_id.present?
          User.includes(:admin_account).find_by(id: user_id)
        else
          nil
        end
    end

    def safe_locale_param
      candidate = params[:locale].presence
      AppConstants::Locales.find(candidate)&.dig(:code) || AppConstants::Locales::DEFAULT_CODE
    end

    def active_locale_entry
      @active_locale_entry || AppConstants::Locales.find(safe_locale_param)
    end

    def available_locale_entries
      AppConstants::Locales::AVAILABLE
    end

    def demo_session_key
      AppConstants::Sessions.key(:demo)
    end
  end
end
