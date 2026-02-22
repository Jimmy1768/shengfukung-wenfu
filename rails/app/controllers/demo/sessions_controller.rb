module Demo
  class SessionsController < BaseController
    skip_before_action :ensure_admin!, only: %i[new create destroy]
    skip_before_action :verify_authenticity_token, only: :destroy
    before_action :prepare_demo_credentials, only: %i[new create]
    before_action :redirect_if_authenticated, only: :new

    def new; end

    def create
      user = demo_user
      unless user
        flash.now[:alert] = I18n.t("demo_admin.flash.seed_missing", command: "bin/rails db:seed")
        render :new, status: :unprocessable_entity
        return
      end

      if valid_demo_credentials?
        establish_admin_session!(user)
        redirect_to marketing_admin_dashboard_path(locale: safe_locale_param),
          notice: I18n.t("demo_admin.flash.welcome_back")
      else
        flash.now[:alert] = I18n.t("demo_admin.flash.invalid_credentials")
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      reset_session
      redirect_to marketing_admin_login_path(locale: params[:locale]),
        notice: I18n.t("demo_admin.flash.signed_out")
    end

    private

    def prepare_demo_credentials
      @dummy_email = default_admin_email
      @dummy_password = default_admin_password
    end

    def redirect_if_authenticated
      return unless admin_signed_in?

      redirect_to marketing_admin_dashboard_path(locale: safe_locale_param)
    end

    def valid_demo_credentials?
      creds = session_params
      email = creds[:email].to_s.downcase.strip
      password = creds[:password].to_s
      return false if email.blank? || password.blank?

      secure_compare(email, default_admin_email.downcase) &&
        secure_compare(password, default_admin_password)
    end

    def establish_admin_session!(user)
      reset_session
      session[AppConstants::Sessions.key(:demo)] = user.id
    end

    def demo_user
      @demo_user ||= User.includes(:admin_account).find_by(email: default_admin_email)
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
