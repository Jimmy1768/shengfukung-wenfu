module Account
  class SignupsController < BaseController
    skip_before_action :authenticate_user!, only: %i[new create]
    skip_before_action :verify_authenticity_token, only: :create

    before_action :redirect_if_signed_in, only: :new
    before_action :capture_entry_intent_from_params!, only: :new

    def new
      redirect_to account_login_path(register: "email")
    end

    def create
      @registration_form = Account::RegistrationForm.new(registration_params)
      if @registration_form.save
        establish_user_session!(@registration_form.user)
        redirect_to account_dashboard_path, notice: "Account created."
      else
        flash.now[:alert] = "We couldn't create your account yet."
        @show_registration_modal = true
        render "account/sessions/new", status: :unprocessable_entity
      end
    end

    private

    def registration_params
      params.fetch(:registration, ActionController::Parameters.new)
        .permit(:email, :password, :password_confirmation)
    end

    def redirect_if_signed_in
      redirect_to account_dashboard_path if user_signed_in?
    end
  end
end
