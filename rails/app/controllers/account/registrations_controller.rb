# frozen_string_literal: true

module Account
  class RegistrationsController < BaseController
    before_action :set_registration, only: %i[show edit update payment start_checkout checkout_return]
    before_action :assign_offering_from_params, only: %i[new create]
    before_action :assign_eligible_registrants, only: %i[new create edit update]
    before_action :ensure_selected_registrant, only: %i[new create]
    before_action :redirect_gathering_edits!, only: %i[edit update]

    helper_method :existing_registration_for
    helper_method :registration_lifecycle_policy
    helper_method :open_assistance_request_for

    def index
      @registrations = registration_scope.order(created_at: :desc)
      preload_open_assistance_requests
    end

    def show
      preload_open_assistance_requests
    end

    def new
      @form = build_form_from_selected_registrant
      @existing_registration = existing_registration_for(selected_registrant_scope, selected_dependent_id)
      @metadata_form = Account::RegistrationMetadataForm.new(registration: @existing_registration, user: current_user) if @existing_registration
    end

    def create
      @form = Account::RegistrationIntakeForm.new(
        user: current_user,
        offering: @offering,
        params: registration_intake_params.merge(registrant_scope: selected_registrant_scope, dependent_id: selected_dependent_id)
      )
      @existing_registration = existing_registration_for(selected_registrant_scope, selected_dependent_id)
      @metadata_form = Account::RegistrationMetadataForm.new(registration: @existing_registration, user: current_user) if @existing_registration

      if @form.save
        log_registration_event!("account.registrations.created", target: @form.registration, changed_fields: registration_intake_params.keys)
        redirect_to payment_account_registration_path(@form.registration),
          notice: "Registration submitted."
      else
        flash.now[:alert] = "Please review the errors below."
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @form = Account::RegistrationMetadataForm.new(registration: @registration, user: current_user)
    end

    def update
      @form = Account::RegistrationMetadataForm.new(
        registration: @registration,
        user: current_user,
        params: metadata_params
      )

      if @form.save
        log_registration_event!("account.registrations.updated", target: @registration, changed_fields: metadata_params.keys)
        redirect_to account_registration_path(@registration), notice: "Registration updated."
      else
        flash.now[:alert] = "Please review the errors below."
        render :edit, status: :unprocessable_content
      end
    end

    def payment
      @registration_period_label = period_label_for(@registration)
      @payment_provider_label = Payments::ProviderResolver.label_for(Payments::ProviderResolver.current_provider)
    end

    def start_checkout
      provider = Payments::ProviderResolver.current_provider
      result = Payments::CheckoutService.new.call(
        registration: @registration,
        amount_cents: @registration.total_price_cents,
        currency: @registration.currency,
        provider: provider,
        idempotency_key: checkout_idempotency_key,
        intent_key: "registration:#{@registration.id}",
        metadata: Payments::CheckoutFlow.metadata_for(
          registration: @registration,
          source: "account_portal",
          temple_slug: current_temple.slug,
          return_url: checkout_return_account_registration_url(@registration, provider: provider),
          cancel_url: checkout_return_account_registration_url(@registration, provider: provider, canceled: 1)
        )
      )

      log_payment_checkout_started!(provider: provider, payment: result.payment, reused: result.reused)

      redirect_url = Payments::CheckoutFlow.redirect_url_for(result)
      return redirect_to redirect_url, allow_other_host: true if redirect_url.present?

      message = if result.reused
                  "A payment attempt already exists. Waiting for confirmation."
                else
                  "#{Payments::ProviderResolver.label_for(provider)} checkout started. Waiting for confirmation."
                end

      redirect_to payment_account_registration_path(@registration), notice: message
    rescue StandardError => e
      redirect_to payment_account_registration_path(@registration), alert: "Unable to start checkout: #{e.message}"
    end

    def checkout_return
      provider = checkout_return_provider
      if ActiveModel::Type::Boolean.new.cast(params[:canceled])
        return redirect_to payment_account_registration_path(@registration), alert: "Payment was canceled before completion."
      end

      result = Payments::CheckoutReturnService.new.call(
        registration: @registration,
        provider: provider,
        params: checkout_return_params
      )

      log_payment_checkout_returned!(provider: provider, payment: result.payment)

      notice =
        if result.payment.completed?
          "Payment confirmed successfully."
        elsif result.payment.failed?
          "Payment failed. Please try again or contact the temple."
        else
          "Payment is still pending confirmation."
        end

      redirect_to payment_account_registration_path(@registration), notice: notice
    rescue ActiveRecord::RecordNotFound
      redirect_to payment_account_registration_path(@registration), alert: "We could not find a matching payment attempt."
    rescue StandardError => e
      redirect_to payment_account_registration_path(@registration), alert: "Unable to verify payment status: #{e.message}"
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
        :quantity,
        :registrant_scope,
        :dependent_id,
        :contact_name,
        :contact_phone,
        :contact_email,
        :household_notes,
        :arrival_window,
        :ceremony_notes
      )
    end

    def redirect_gathering_edits!
      return if registration_lifecycle_policy.gathering_editable?

      redirect_to account_registration_path(@registration), alert: "社群聚會報名建立後不可編輯。"
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

    def registration_lifecycle_policy
      @registration_lifecycle_policy ||= Registrations::LifecyclePolicy.new(@registration)
    end

    def checkout_idempotency_key
      params[:idempotency_key].presence || "acct-reg-#{@registration.id}-#{SecureRandom.hex(4)}"
    end

    def checkout_return_provider
      params[:provider].presence || @registration.temple_payments.order(created_at: :desc).limit(1).pick(:provider) || Payments::ProviderResolver.current_provider
    end

    def checkout_return_params
      params.permit(:transactionId, :orderId, :canceled).to_h.transform_keys do |key|
        case key
        when "transactionId" then "transaction_id"
        when "orderId" then "order_id"
        else key
        end
      end
    end

    def preload_open_assistance_requests
      @open_assistance_requests_by_registration_id = current_temple.temple_assistance_requests
        .open_requests
        .where(user: current_user)
        .pluck(:temple_registration_id, :id)
        .each_with_object({}) do |(registration_id, request_id), buffer|
          buffer[registration_id] = request_id
        end
    end

    def open_assistance_request_for(registration)
      return nil if registration.blank?

      request_id = (@open_assistance_requests_by_registration_id || {})[registration.id]
      request_id.present? ? request_id : nil
    end

    def log_registration_event!(action, target:, changed_fields:)
      SystemAuditLogger.log!(
        action: action,
        admin: current_user,
        target: target,
        temple: current_temple,
        metadata: {
          actor_type: "user",
          registration_reference: target.reference_code,
          changed_fields: Array(changed_fields).map(&:to_s)
        }
      )
    end

    def log_payment_checkout_started!(provider:, payment:, reused:)
      SystemAuditLogger.log!(
        action: "account.payments.checkout_started",
        admin: current_user,
        target: payment,
        temple: current_temple,
        metadata: {
          actor_type: "user",
          registration_reference: @registration.reference_code,
          payment_reference: payment.provider_reference.presence || payment.id,
          provider: provider.to_s,
          source: "account_portal",
          reused: reused
        }
      )
    end

    def log_payment_checkout_returned!(provider:, payment:)
      SystemAuditLogger.log!(
        action: "account.payments.checkout_returned",
        admin: current_user,
        target: payment,
        temple: current_temple,
        metadata: {
          actor_type: "user",
          registration_reference: @registration.reference_code,
          payment_reference: payment.provider_reference.presence || payment.id,
          provider: provider.to_s,
          source: "checkout_return",
          status: payment.status
        }
      )
    end
  end
end
