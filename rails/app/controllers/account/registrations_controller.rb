# frozen_string_literal: true

module Account
  class RegistrationsController < BaseController
    before_action :set_registration, only: %i[show edit update payment]
    before_action :assign_offering_from_params, only: %i[new create]
    before_action :redirect_existing_registration!, only: %i[new create]

    def index
      @registrations = registration_scope.order(created_at: :desc)
    end

    def show; end

    def new
      @form = Account::RegistrationIntakeForm.new(
        user: current_user,
        offering: @offering
      )
    end

    def create
      @form = Account::RegistrationIntakeForm.new(
        user: current_user,
        offering: @offering,
        params: registration_intake_params
      )

      if @form.save
        redirect_to payment_account_registration_path(@form.registration),
          notice: "Registration submitted."
      else
        flash.now[:alert] = "Please review the errors below."
        render :new, status: :unprocessable_entity
      end
    end

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

    def payment; end

    private

    def registration_scope
      current_user.temple_event_registrations.includes(:registrable)
    end

    def assign_offering_from_params
      return unless action_name.in?(%w[new create])

      slug = params[:offering].presence
      action = params[:account_action].presence
      @offering = find_offering_for_intent(slug, action)
      if @offering.blank?
        redirect_to account_dashboard_path, alert: "We couldn't find that offering."
      else
        @account_action = params[:account_action].presence || account_action_for(@offering)
      end
    end

    def redirect_existing_registration!
      return unless @offering

      return unless (registration = find_registration_for_offering(@offering))

      redirect_to account_registration_path(registration)
    end

    def set_registration
      @registration = registration_scope.find(params[:id])
    end

    def registration_intake_params
      params.fetch(:account_registration_intake_form, {}).permit(
        :quantity,
        :contact_name,
        :contact_phone,
        :contact_email,
        :household_notes,
        :arrival_window,
        :ceremony_notes
      )
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
