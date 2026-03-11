# frozen_string_literal: true

module Account
  class SettingsController < BaseController
    def show
      @password_form = Account::PasswordSettingsForm.new(user: current_user)
    end

    def update
      @password_form = Account::PasswordSettingsForm.new(user: current_user, params: password_params)
      if @password_form.save
        redirect_to account_settings_path, notice: t("account.settings.flash.password_enabled")
      else
        flash.now[:alert] = t("account.settings.flash.update_failed")
        render :show, status: :unprocessable_content
      end
    end

    private

    def password_params
      params.fetch(:account_password_settings_form, ActionController::Parameters.new)
        .permit(:password, :password_confirmation)
    end
  end
end
