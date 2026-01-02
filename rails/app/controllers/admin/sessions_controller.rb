module Admin
  class SessionsController < BaseController
    skip_before_action :authenticate_admin!, only: %i[new create destroy]
    skip_before_action :verify_authenticity_token, only: %i[create destroy]

    def new
    end

    def create
      user = User.includes(:admin_account).find_by(email: default_admin_email)
      unless user&.admin_account&.active?
        flash.now[:alert] = "No admin account found. Run `bin/rails db:seed` to provision access."
        render :new, status: :unprocessable_entity
        return
      end

      if valid_credentials?
        establish_admin_session!(user)
        redirect_to admin_dashboard_path, notice: "Signed in to the admin console."
      else
        flash.now[:alert] = "Those credentials did not match. Use the seeded email/password."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      destroy_admin_session!
      redirect_to admin_login_path, notice: "Signed out."
    end

    private

    def valid_credentials?
      creds = session_params
      email = creds[:email].to_s.downcase.strip
      password = creds[:password].to_s
      return false if email.blank? || password.blank?

      secure_compare(email, default_admin_email.downcase) &&
        secure_compare(password, default_admin_password)
    end

    def session_params
      params.fetch(:session, ActionController::Parameters.new).permit(:email, :password)
    end

    def secure_compare(value, other)
      return false if value.blank? || other.blank?
      return false unless value.bytesize == other.bytesize

      ActiveSupport::SecurityUtils.secure_compare(value, other)
    end

    def default_admin_email
      ENV.fetch("PROJECT_DEFAULT_ADMIN_EMAIL") do
        "admin@#{AppConstants::Project.slug}.local"
      end
    end

    def default_admin_password
      ENV.fetch("PROJECT_DEFAULT_ADMIN_PASSWORD", "Password123!")
    end
  end
end
