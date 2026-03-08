module Account
  class BaseController < ApplicationController
    include TempleContext
    include Account::RegistrationIntent
    include ApiProtection::ControllerGuard
    layout "account"

    helper Forms::LayoutHelper
    helper_method :current_user,
      :user_signed_in?,
      :oauth_account_linking_enabled?,
      :account_theme_options,
      :current_account_theme_label,
      :current_account_display_mode_id,
      :active_nav?,
      :active_temple_slug,
      :current_account_locale,
      :account_locale_options

    prepend_before_action :enforce_request_audit!
    before_action :assign_active_temple_slug
    before_action :ensure_temple_context
    before_action :assign_account_theme
    before_action :apply_account_locale
    before_action :authenticate_user!

    private
    ACCOUNT_TEMPLE_SESSION_KEY = "account_active_temple_slug"
    ACCOUNT_ENTRY_INTENT_SESSION_KEY = "account_entry_intent"
    ACCOUNT_LOCALE_SESSION_KEY = AppConstants::Sessions.key(:account_locale)
    ACCOUNT_LOCALE_COOKIE_KEY = "account_locale"

    def assign_account_theme
      resolved = Themes::Policy.resolve(
        surface: :account,
        persisted_mode: persisted_account_display_mode,
        cookie_value: cookies[Themes::Policy.cookie_key(:account)],
        project_default: AppConstants::Project.default_theme_key
      )
      @active_theme_key = resolved.fetch(:palette_key)
      @active_account_display_mode_id = resolved.fetch(:mode_id)
      @theme_palette = Themes.for(@active_theme_key)
    end

    def persisted_account_display_mode
      current_user&.user_preference&.display_mode_for(:account)
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

      redirect_to account_login_path, alert: I18n.t("account.sessions.flash.sign_in_required")
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

    def oauth_account_linking_enabled?
      FeatureFlags::Evaluator.enabled?("oauth_account_linking", actor: current_user)
    end

    def establish_user_session!(user)
      preserved_temple_slug = @active_temple_slug.presence || session[ACCOUNT_TEMPLE_SESSION_KEY]
      preserved_intent = session[ACCOUNT_ENTRY_INTENT_SESSION_KEY]
      preserved_locale = current_account_locale
      reset_session
      session[ACCOUNT_TEMPLE_SESSION_KEY] = preserved_temple_slug if preserved_temple_slug.present?
      session[ACCOUNT_ENTRY_INTENT_SESSION_KEY] = preserved_intent if preserved_intent.present?
      session[ACCOUNT_LOCALE_SESSION_KEY] = preserved_locale if preserved_locale.present?
      session[AppConstants::Sessions.key(:account)] = user.id
    end

    def destroy_user_session!
      preserved_locale = current_account_locale
      reset_session
      session[ACCOUNT_LOCALE_SESSION_KEY] = preserved_locale if preserved_locale.present?
    end

    def account_theme_options
      Themes::Policy.options(:account, locale: current_account_locale)
    end

    def current_account_theme_label
      account_theme_options.find { |option| option[:id] == current_account_display_mode_id }&.dig(:label) || current_account_display_mode_id
    end

    def current_account_display_mode_id
      @active_account_display_mode_id
    end

    def account_locale_options
      [
        { label: "繁體中文", value: :"zh-TW" },
        { label: "English", value: :en }
      ]
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

    def current_account_locale
      @current_account_locale ||= begin
        stored = session[ACCOUNT_LOCALE_SESSION_KEY]
        cookie_locale = cookies[ACCOUNT_LOCALE_COOKIE_KEY]
        locale = stored.presence || cookie_locale.presence || persisted_account_locale.presence || I18n.default_locale
        normalize_account_locale(locale)
      end
    end

    def persisted_account_locale
      current_user&.user_preference&.locale
    end

    def persist_account_locale!(locale)
      normalized = normalize_account_locale(locale)
      session[ACCOUNT_LOCALE_SESSION_KEY] = normalized
      cookies[ACCOUNT_LOCALE_COOKIE_KEY] = {
        value: normalized.to_s,
        expires: 1.year.from_now,
        secure: Rails.env.production?,
        httponly: false,
        same_site: :lax
      }
      normalized
    end

    def normalize_account_locale(locale)
      locale_sym = locale&.to_sym
      return I18n.default_locale unless I18n.available_locales.include?(locale_sym)

      locale_sym
    end

    def apply_account_locale
      I18n.locale = current_account_locale
    end

    def capture_entry_intent_from_params!
      registration_ref = params[:registration]
      registration_ref = nil unless registration_ref.is_a?(String)

      intent = {
        temple: params[:temple].presence,
        account_action: params[:account_action].presence,
        offering_slug: params[:offering].presence,
        registration_reference: registration_ref
      }.compact
      store_account_entry_intent!(intent) if intent.present?
    end

    def find_registration_by_reference(reference_code)
      return nil if reference_code.blank?

      registration_search_scope.find_by(reference_code:)
    end

    def resolve_post_login_path
      intent = (account_entry_intent || {}).deep_symbolize_keys
      clear_account_entry_intent!

      return account_dashboard_path if intent.blank?

      if intent[:registration_reference].present?
        if (registration = find_registration_by_reference(intent[:registration_reference]))
          return account_registration_path(registration)
        end
      end

      offering = find_offering_for_intent(intent[:offering_slug], intent[:account_action])

      if offering.present?
        if (registration = find_registration_for_offering(offering))
          return account_registration_path(registration)
        end

        intent_path = new_account_registration_path(
          temple: intent[:temple].presence || current_temple&.slug,
          account_action: account_action_for(offering),
          offering: offering.slug
        )
        return intent_path if intent_path
      end

      account_dashboard_path
    end
  end
end
