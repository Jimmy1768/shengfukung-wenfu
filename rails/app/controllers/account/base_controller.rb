module Account
  class BaseController < ApplicationController
    include TempleContext
    layout "account"

    helper Forms::LayoutHelper
    helper_method :current_user,
      :user_signed_in?,
      :account_theme_options,
      :active_nav?,
      :active_temple_slug

    before_action :assign_active_temple_slug
    before_action :ensure_temple_context
    before_action :assign_account_theme
    before_action :authenticate_user!

    private
    THEME_COOKIE_KEY = "temple_theme"
    ACCOUNT_THEME_CHOICES = %w[temple-1 golden-light].freeze
    ACCOUNT_TEMPLE_SESSION_KEY = "account_active_temple_slug"
    ACCOUNT_ENTRY_INTENT_SESSION_KEY = "account_entry_intent"

    def assign_account_theme
      key = if allow_theme_override?
        cookie_value = cookies[THEME_COOKIE_KEY]
        cookie_value if valid_theme_key?(cookie_value)
      end
      key ||= AppConstants::Project.default_theme_key

      @active_theme_key = sanitize_theme_key(key)
      @theme_palette = Themes.for(@active_theme_key)
    end

    def assign_active_temple_slug
      requested_slug = params[:temple].presence
      if requested_slug.present?
        session[ACCOUNT_TEMPLE_SESSION_KEY] = requested_slug
      end

      @active_temple_slug = session[ACCOUNT_TEMPLE_SESSION_KEY].presence
    end

    def ensure_temple_context
      return if @active_temple_slug.present?

      redirect_to account_temples_path
    end

    def active_temple_slug
      @active_temple_slug
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
      preserved_temple_slug = @active_temple_slug.presence || session[ACCOUNT_TEMPLE_SESSION_KEY]
      preserved_intent = session[ACCOUNT_ENTRY_INTENT_SESSION_KEY]
      reset_session
      session[ACCOUNT_TEMPLE_SESSION_KEY] = preserved_temple_slug if preserved_temple_slug.present?
      session[ACCOUNT_ENTRY_INTENT_SESSION_KEY] = preserved_intent if preserved_intent.present?
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

    def resolved_temple_slug
      session[ACCOUNT_TEMPLE_SESSION_KEY].presence || super
    end

    def store_account_entry_intent!(payload)
      session[ACCOUNT_ENTRY_INTENT_SESSION_KEY] = payload.compact
    end

    def clear_account_entry_intent!
      session.delete(ACCOUNT_ENTRY_INTENT_SESSION_KEY)
    end

    def account_entry_intent
      session[ACCOUNT_ENTRY_INTENT_SESSION_KEY] || {}
    end

    def capture_entry_intent_from_params!
      intent = {
        temple: params[:temple].presence,
        account_action: params[:account_action].presence,
        offering_slug: params[:offering].presence,
        registration_reference: params[:registration].presence
      }.compact
      store_account_entry_intent!(intent) if intent.present?
    end
  end
end
