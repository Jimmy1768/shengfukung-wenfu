module Account
  class BaseController < ActionController::Base
    include TempleContext
    layout "account"
    protect_from_forgery with: :exception

    helper Forms::LayoutHelper
    helper_method :current_user, :user_signed_in?, :account_theme_options, :active_nav?

    before_action :assign_account_theme

    before_action :authenticate_user!

    private
    THEME_COOKIE_KEY = "temple_theme"
    ACCOUNT_THEME_CHOICES = %w[temple-1 golden-light].freeze

    def assign_account_theme
      key = if allow_theme_override?
        cookie_value = cookies[THEME_COOKIE_KEY]
        cookie_value if valid_theme_key?(cookie_value)
      end
      key ||= AppConstants::Project.default_theme_key

      @active_theme_key = sanitize_theme_key(key)
      @theme_palette = Themes.for(@active_theme_key)
    end

    def authenticate_user!
      return if user_signed_in?

      redirect_to account_login_path, alert: "Please sign in to continue."
    end

    def user_signed_in?
      current_user.present?
    end

    def current_user
      return @current_user if defined?(@current_user)

      user_id = session[AppConstants::Sessions.key(:account)]
      @current_user =
        if user_id.present?
          User.find_by(id: user_id)
        else
          nil
        end
    end

    def establish_user_session!(user)
      reset_session
      session[AppConstants::Sessions.key(:account)] = user.id
    end

    def destroy_user_session!
      reset_session
    end

    def allow_theme_override?
      Rails.env.development?
    end

    def sanitize_theme_key(value)
      valid_theme_key?(value) ? value : ACCOUNT_THEME_CHOICES.first
    end

    def valid_theme_key?(value)
      ACCOUNT_THEME_CHOICES.include?(value.to_s)
    end

    def account_theme_options
      ACCOUNT_THEME_CHOICES.map do |key|
        {
          id: key,
          label: Themes::Palettes::RAW_CONFIG.dig("themes", key, "label") || key.humanize
        }
      end
    end

    def active_nav?(path)
      request.path == path
    end
  end
end
