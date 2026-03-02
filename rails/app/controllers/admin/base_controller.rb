module Admin
  class BaseController < ApplicationController
    include TempleContext
    include AdminPermissionEnforcer
    include ApiProtection::ControllerGuard

    layout "admin"

    helper Forms::LayoutHelper
    helper Admin::FiltersHelper
    helper_method :current_admin,
                  :admin_signed_in?,
                  :available_admin_temples,
                  :allow_temple_switch?,
                  :admin_theme_options,
                  :current_admin_theme_label,
                  :current_admin_display_mode_id,
                  :current_admin_locale,
                  :admin_locale_options,
                  :admin_brand_name,
                  :admin_brand_slug

    prepend_before_action :enforce_request_audit!
    before_action :authenticate_admin!
    before_action :ensure_admin_temple_scope
    before_action :assign_admin_theme
    before_action :apply_admin_locale

    TEMPLE_SELECTION_SESSION_KEY = AppConstants::Sessions.key(:admin_temple)
    LOCALE_SESSION_KEY = AppConstants::Sessions.key(:admin_locale)

    private

    def authenticate_admin!
      return if admin_signed_in?

      redirect_to admin_login_path, alert: "Please sign in to access the admin console."
    end

    def admin_signed_in?
      current_admin&.admin_account&.active?
    end

    def current_admin
      return @current_admin if defined?(@current_admin)

      user_id = session[AppConstants::Sessions.key(:admin)]
      @current_admin =
        if user_id.present?
          User.includes(:admin_account).find_by(id: user_id)
        else
          nil
        end
    end

    def establish_admin_session!(user)
      reset_session
      session[AppConstants::Sessions.key(:admin)] = user.id
      set_admin_selected_temple_slug(default_admin_temple_slug(user.admin_account))
    end

    def destroy_admin_session!
      reset_session
    end

    def available_admin_temples
      return Temple.none unless admin_signed_in?

      @available_admin_temples ||= Temple.for_admin(current_admin.admin_account).order(:name)
    end

    def allow_temple_switch?
      return false if Rails.env.production?

      admin_signed_in? &&
        current_admin.admin_account.owner_role? &&
        available_admin_temples.size > 1
    end

    def ensure_admin_temple_scope
      return unless admin_signed_in?

      temples = available_admin_temples.to_a
      if temples.empty?
        destroy_admin_session!
        redirect_to admin_login_path, alert: "Your account is not assigned to any temples yet."
        return
      end

      slug = admin_selected_temple_slug
      return if slug.present? && temples.any? { |temple| temple.slug == slug }

      set_admin_selected_temple_slug(temples.first.slug)
    end

    def admin_selected_temple_slug
      session[TEMPLE_SELECTION_SESSION_KEY]
    end

    def set_admin_selected_temple_slug(slug)
      session[TEMPLE_SELECTION_SESSION_KEY] = slug
    end

    def assign_admin_theme
      resolved = Themes::Policy.resolve(
        surface: :admin,
        persisted_mode: persisted_admin_display_mode,
        cookie_value: cookies[Themes::Policy.cookie_key(:admin)],
        project_default: AppConstants::Project.default_theme_key
      )
      @active_theme_key = resolved.fetch(:palette_key)
      @active_admin_display_mode_id = resolved.fetch(:mode_id)
      @theme_palette = Themes.for(@active_theme_key)
    end

    def persisted_admin_display_mode
      current_admin&.user_preference&.display_mode_for(:admin)
    end

    def admin_theme_options
      Themes::Policy.options(:admin, locale: current_admin_locale)
    end

    def current_admin_theme_label
      admin_theme_options.find { |option| option[:id] == current_admin_display_mode_id }&.dig(:label) || current_admin_display_mode_id
    end

    def current_admin_display_mode_id
      @active_admin_display_mode_id
    end

    def default_admin_temple_slug(admin_account)
      return nil unless admin_account

      admin_account.temples.order(:name).limit(1).pluck(:slug).first
    end

    def current_admin_locale
      @current_admin_locale ||= begin
        stored = session[LOCALE_SESSION_KEY]
        locale = stored.presence || I18n.default_locale
        normalize_admin_locale(locale)
      end
    end

    def admin_locale_options
      [
        { label: "English", value: :en },
        { label: "繁體中文", value: :"zh-TW" }
      ]
    end

    def normalize_admin_locale(locale)
      locale_sym = locale&.to_sym
      return I18n.default_locale unless I18n.available_locales.include?(locale_sym)

      locale_sym
    end

    def apply_admin_locale
      I18n.locale = normalize_admin_locale(session[LOCALE_SESSION_KEY])
    end

    def admin_brand_name
      return "Temple Management System" unless admin_signed_in?

      current_temple&.name || AppConstants::Project.name
    end

    def admin_brand_slug
      return nil unless admin_signed_in?

      AppConstants::Project.slug
    end

    def filter_params
      @filter_params ||= params
        .fetch(:filter, {})
        .permit(:query, :offering_id, :offering_reference, :offering_kind, :payment_method, :start_date, :end_date, :status)
        .to_h
        .symbolize_keys
    end

    def normalized_filter_params
      @normalized_filter_params ||= begin
        normalized = filter_params.transform_values do |value|
          value.respond_to?(:presence) ? value.presence : value
        end
        reference = normalized[:offering_reference]
        reference ||= normalized[:offering_id].present? ? "#{TempleEvent.name}:#{normalized[:offering_id]}" : nil
        if reference.present?
          type, id = reference.split(":", 2)
          normalized[:offering_reference] = reference
          normalized[:offering_type] = normalize_offering_type(type)
          normalized[:offering_id] = id if id.present?
        elsif normalized[:offering_kind].present?
          normalized[:offering_type] = normalize_offering_kind(normalized[:offering_kind])
        end
        normalized
      end
    end

    def normalize_offering_type(type)
      return nil if type.blank?

      case type
      when "TempleService", TempleService.name
        "TempleService"
      when "TempleEvent", TempleEvent.name, TempleOffering.name
        "TempleEvent"
      else
        type
      end
    end

    def normalize_offering_kind(kind)
      case kind.to_s
      when "events"
        "TempleEvent"
      when "services"
        "TempleService"
      when "gatherings"
        "TempleGathering"
      else
        nil
      end
    end

    def filter_hidden_params
      request.query_parameters.except("filter")
    end

  end
end
