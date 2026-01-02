module Account
  class BaseController < ActionController::Base
    layout "account"
    protect_from_forgery with: :exception

    helper Forms::LayoutHelper
    helper_method :current_user, :user_signed_in?

    before_action :authenticate_user!

    private

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
  end
end
