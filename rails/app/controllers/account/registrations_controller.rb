# frozen_string_literal: true

module Account
  class RegistrationsController < BaseController
    before_action :set_registration, only: %i[show edit update payment]
    before_action :assign_offering_from_params, only: %i[new create]
    before_action :assign_eligible_registrants, only: %i[new create]
    before_action :ensure_selected_registrant, only: %i[new create]

    helper_method :existing_registration_for

    def index
      @registrations = registration_scope.order(created_at: :desc)
    end

    def show; end

    def new
      @form = build_form_from_selected_registrant
      @existing_registration = existing_registration_for(selected_registrant_scope, selected_dependent_id)
      @metadata_form = Account::RegistrationMetadataForm.new(registration: @existing_registration) if @existing_registration
    end

    def create
      @form = Account::RegistrationIntakeForm.new(
        user: current_user,
        offering: @offering,
        params: registration_intake_params.merge(registrant_scope: selected_registrant_scope, dependent_id: selected_dependent_id)
      )
      @existing_registration = existing_registration_for(selected_registrant_scope, selected_dependent_id)
      @metadata_form = Account::RegistrationMetadataForm.new(registration: @existing_registration) if @existing_registration

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

    def payment
      @registration_period_label = period_label_for(@registration)
    end

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

    def assign_eligible_registrants
      @dependents = current_user.dependents.order(:native_name, :english_name)
      @registrant_options = [
        { scope: "self", label: current_user.native_name.presence || current_user.english_name.presence || current_user.email }
      ] +
        @dependents.map { |dep| { scope: "dependent", dependent: dep, label: dep.native_name.presence || dep.english_name } }
    end

    def ensure_selected_registrant
      return unless @offering

      chosen_scope = params[:registrant_scope].presence
      chosen_id = params[:dependent_id].presence

      if chosen_scope == "dependent" && chosen_id.present?
        @selected_registrant_scope = "dependent"
        @selected_dependent_id = chosen_id
      else
        @selected_registrant_scope = "self"
        @selected_dependent_id = nil
      end
    end

    def selected_registrant_scope
      @selected_registrant_scope || "self"
    end

    def selected_dependent_id
      @selected_dependent_id.presence
    end

    def existing_registration_for(scope, dependent_id)
      return nil unless @offering

      @existing_registration_cache ||= {}
      key = [scope, dependent_id.presence].join(":")
      return @existing_registration_cache[key] if @existing_registration_cache.key?(key)

      @existing_registration_cache[key] = Registrations::ExistingLookup.new(
        scope: current_user.temple_event_registrations,
        offering: @offering,
        user_id: current_user.id,
        registrant_scope: scope,
        dependent_id:
      ).find
    end

    def build_form_from_selected_registrant
      defaults = { registrant_scope: selected_registrant_scope, dependent_id: selected_dependent_id }
      Account::RegistrationIntakeForm.new(
        user: current_user,
        offering: @offering,
        params: defaults
      )
    end

    def period_label_for(registration)
      metadata = (registration.metadata || {}).with_indifferent_access
      period_key = metadata[:registration_period_key].presence
      period_key ||= registration.registrable.registration_period_key if registration.registrable.respond_to?(:registration_period_key)
      return if period_key.blank?

      current_temple.registration_period_label_for(period_key)
    end
  end
end
