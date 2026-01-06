module Admin
  class BaseController < ActionController::Base
    include TempleContext
    include AdminPermissionEnforcer

    layout "admin"
    protect_from_forgery with: :exception

    helper Forms::LayoutHelper
    helper_method :current_admin, :admin_signed_in?, :available_admin_temples, :allow_temple_switch?

    before_action :authenticate_admin!
    before_action :ensure_admin_temple_scope

    TEMPLE_SELECTION_SESSION_KEY = AppConstants::Sessions.key(:admin_temple)

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
  end
end
