module Admin
  class SessionsController < BaseController
    skip_before_action :authenticate_admin!, only: %i[new create destroy]
    skip_before_action :verify_authenticity_token, only: %i[create destroy]

    def new; end

    def create
      credentials = session_params
      user = User.includes(:admin_account).find_by(email: credentials[:email]&.downcase)

      if can_sign_in?(user, credentials[:password])
        establish_admin_session!(user)
        redirect_to admin_dashboard_path, notice: "Signed in to the admin console."
      else
        flash.now[:alert] = "Those credentials did not match. Use an active admin account."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      destroy_admin_session!
      redirect_to admin_login_path, notice: "Signed out."
    end

    private

    def can_sign_in?(user, password)
      return false unless user&.admin_account&.active?

      secure_compare(user.encrypted_password, User.password_hash(password.to_s))
    end

    def session_params
      params.fetch(:session, ActionController::Parameters.new).permit(:email, :password)
    end

    def secure_compare(value, other)
      return false if value.blank? || other.blank?
      return false unless value.bytesize == other.bytesize

      ActiveSupport::SecurityUtils.secure_compare(value, other)
    end
  end
end
