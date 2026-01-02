module Account
  class SessionsController < BaseController
    skip_before_action :authenticate_user!, only: %i[new create destroy]
    skip_before_action :verify_authenticity_token, only: %i[create destroy]

    def new
      @registration_form = Account::RegistrationForm.new
      @show_registration_modal = params[:register] == "email"
    end

    def create
      if valid_credentials?
        user = User.find_by(email: session_params[:email].to_s.downcase.strip)
        establish_user_session!(user)
        redirect_to account_dashboard_path, notice: "Signed in."
      else
        flash.now[:alert] = "Those credentials did not match."
        @registration_form ||= Account::RegistrationForm.new
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      destroy_user_session!
      redirect_to account_login_path, notice: "Signed out."
    end

    private

    def valid_credentials?
      creds = session_params
      email = creds[:email].to_s.downcase.strip
      password = creds[:password].to_s
      return false if email.blank? || password.blank?

      user = User.find_by(email: email)
      return false unless user

      hashed = User.password_hash(password)

      secure_compare(user.encrypted_password, hashed)
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
