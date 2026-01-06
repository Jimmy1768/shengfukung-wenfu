# frozen_string_literal: true

module Account
  class RegistrationsController < BaseController
    before_action :set_registration, only: %i[show edit update]

    def index
      @registrations = registration_scope.order(created_at: :desc)
    end

    def show; end

    def edit
      @form = Account::RegistrationMetadataForm.new(registration: @registration)
    end

    def update
      @form = Account::RegistrationMetadataForm.new(
        registration: @registration,
        params: metadata_params
      )

      if @form.save
        redirect_to account_registration_path(@registration), notice: "Registration updated."
      else
        flash.now[:alert] = "Please review the errors below."
        render :edit, status: :unprocessable_content
      end
    end

    private

    def registration_scope
      current_user.temple_event_registrations.includes(:temple_offering)
    end

    def set_registration
      @registration = registration_scope.find(params[:id])
    end

    def metadata_params
      params.require(:account_registration_metadata_form).permit(
        :contact_name,
        :contact_phone,
        :contact_email,
        :household_notes,
        :arrival_window,
        :ceremony_notes
      )
    end
  end
end
