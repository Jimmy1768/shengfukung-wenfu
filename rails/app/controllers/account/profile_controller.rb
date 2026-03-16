# frozen_string_literal: true

module Account
  class ProfileController < BaseController
    def show
      @form = Account::ProfileForm.new(user: current_user)
      @password_form = Account::PasswordSettingsForm.new(user: current_user)
      @contact_temple_form = Account::ContactTempleRequestForm.new
      @assistance_request = current_temple.temple_assistance_requests.open_requests.find_by(user: current_user, temple_registration_id: nil)
      @dependents = current_user.user_dependents.includes(:dependent)
      @oauth_identities = current_user.oauth_identities.recently_active
    end

    def edit
      @form = Account::ProfileForm.new(user: current_user)
    end

    def update
      @form = Account::ProfileForm.new(user: current_user, params: profile_params)
      if @form.save
        log_profile_update!
        redirect_to account_profile_path, notice: "Profile updated."
      else
        flash.now[:alert] = "Please fix the errors below."
        render :edit, status: :unprocessable_content
      end
    end

    private

    def profile_params
      params.require(:account_profile_form).permit(:english_name, :native_name, :phone, :city, :notes)
    end

    def log_profile_update!
      SystemAuditLogger.log!(
        action: "account.profile.updated",
        admin: current_user,
        target: current_user,
        temple: current_temple,
        metadata: {
          actor_type: "user",
          changed_fields: profile_params.keys.map(&:to_s)
        }
      )
    end
  end
end
