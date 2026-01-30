module Admin
  class BaseController < ActionController::Base
    include TempleContext
    include AdminPermissionEnforcer

    layout "admin"
    protect_from_forgery with: :exception

    helper Forms::LayoutHelper
    helper Admin::FiltersHelper
    helper_method :current_admin,
                  :admin_signed_in?,
                  :available_admin_temples,
                  :allow_temple_switch?,
                  :current_admin_locale,
                  :admin_locale_options,
                  :admin_brand_name,
                  :admin_brand_slug

    before_action :authenticate_admin!
    before_action :ensure_admin_temple_scope
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
        .permit(:query, :offering_id, :payment_method, :start_date, :end_date, :status)
        .to_h
        .symbolize_keys
    end

    def normalized_filter_params
      @normalized_filter_params ||= filter_params.transform_values do |value|
        value.respond_to?(:presence) ? value.presence : value
      end
    end

    def filter_hidden_params
      request.query_parameters.except("filter")
    end

  end
end
