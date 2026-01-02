module Admin
  class BaseController < ActionController::Base
    include TempleContext

    layout "admin"
    protect_from_forgery with: :exception

    helper Forms::LayoutHelper
    helper_method :current_admin, :admin_signed_in?

    before_action :authenticate_admin!

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
    end

    def destroy_admin_session!
      reset_session
    end
  end
end
