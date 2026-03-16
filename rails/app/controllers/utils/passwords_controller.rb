# frozen_string_literal: true

module Utils
  # HTML-oriented password reset flow using email-based tokens.
  class PasswordsController < UiGatewayController
    helper Forms::LayoutHelper
    layout "account"
    skip_forgery_protection only: %i[create update]

    def new
      @request_form = Passwords::RequestForm.new
    end

    def create
      @request_form = Passwords::RequestForm.new(request_form_params)

      if @request_form.submit { |user, token| send_reset_email(user, token) }
        redirect_to new_password_path, notice: I18n.t("account.passwords.flash.sent")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      token = params[:token].to_s
      if Auth::PasswordReset.verify_token(token).present?
        @reset_form = Passwords::UpdateForm.new(token: token)
      else
        redirect_to new_password_path, alert: I18n.t("account.passwords.flash.invalid_token")
      end
    end

    def update
      @reset_form = Passwords::UpdateForm.new(reset_form_params)
      if @reset_form.submit
        redirect_to account_login_path, notice: I18n.t("account.passwords.flash.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    helper_method :user_signed_in?

    private

    def user_signed_in?
      false
    end

    def send_reset_email(user, raw_token)
      return if user.blank? || raw_token.blank?

      reset_url = edit_password_url(token: raw_token)
      Auth::PasswordMailer.reset_email(user: user, reset_url: reset_url)
    rescue => e
      Rails.logger.error "[Utils::PasswordsController] Password reset email failed: #{e.class}: #{e.message}"
    end

    def request_form_params
      params.fetch(:passwords_request_form, {}).permit(:email)
    end

    def reset_form_params
      params.fetch(:passwords_update_form, {}).permit(:token, :password, :password_confirmation)
    end
  end
end
