# frozen_string_literal: true

module Admin
  class OfferingOrdersController < BaseController
    before_action :require_manage_registrations!
    before_action :set_offering
    before_action :set_registration, only: :show

    def index
      scope = @offering.temple_event_registrations
      @registrations = scope.recent
      @registrations_total = scope.count
      @registrations_paid = scope.with_status(TempleEventRegistration::PAYMENT_STATUSES[:paid]).count
      @registrations_pending = scope.with_status(TempleEventRegistration::PAYMENT_STATUSES[:pending]).count
      @registrations_total_amount_cents = scope.sum(:total_price_cents)
    end

    def new
      @registration = @offering.temple_event_registrations.new(quantity: 1)
      prepare_registration_payloads
      apply_registration_defaults
    end

    def create
      builder = Payments::OfferingRegistrationBuilder.new(
        temple: current_temple,
        offering: @offering,
        admin_user: current_admin,
        attributes: registration_params
      )

      @registration = builder.create
      redirect_to admin_offering_offering_order_path(@offering, @registration), notice: "Registration created."
    rescue ActiveRecord::RecordInvalid => e
      @registration = e.record
      prepare_registration_payloads
      apply_registration_defaults
      render :new, status: :unprocessable_entity
    end

    def show; end

    private

    def set_offering
      @offering = current_temple.temple_offerings.find(params[:offering_id])
    end

    def set_registration
      @registration = @offering.temple_event_registrations.find(params[:id])
    end

    def require_manage_registrations!
      require_capability!(:manage_registrations)
    end

    def registration_params
      permitted = params.require(:temple_event_registration).permit(
        :user_id,
        :quantity,
        :unit_price_cents,
        :currency,
        :certificate_number,
        :event_slug,
        contact_details: %i[primary_contact email phone dependents_notes notes],
        logistics_details: %i[preferred_date preferred_slot arrival_window ceremony_location],
        ritual_metadata: %i[ancestor_placard_name dedication_message incense_option certificate_notes]
      )
      permitted[:contact_payload] = sanitize_payload(permitted.delete(:contact_details))
      permitted[:logistics_payload] = sanitize_payload(permitted.delete(:logistics_details))
      metadata_fields = sanitize_payload(permitted.delete(:ritual_metadata))
      permitted[:metadata] = metadata_fields
      permitted
    end

    def sanitize_payload(raw_hash)
      return {} if raw_hash.blank?

      raw_hash.to_h.transform_values { |value| value.is_a?(String) ? value.strip : value }.compact_blank
    end

    def prepare_registration_payloads
      @registration.contact_payload ||= {}
      @registration.logistics_payload ||= {}
      @registration.metadata ||= {}
    end

    def apply_registration_defaults
      defaults = registration_form_schema.defaults_for(:order)
      @registration.quantity ||= defaults[:quantity]
      @registration.unit_price_cents ||= defaults[:unit_price_cents] || @offering.price_cents
      @registration.currency ||= defaults[:currency] || @offering.currency
      @registration.certificate_number ||= defaults[:certificate_number]

      merge_payload_defaults(@registration.contact_payload, registration_form_schema.defaults_for(:contact))
      merge_payload_defaults(@registration.logistics_payload, registration_form_schema.defaults_for(:logistics))
      merge_payload_defaults(@registration.metadata, registration_form_schema.defaults_for(:ritual_metadata))
    end

    def merge_payload_defaults(payload, defaults)
      return if defaults.blank?

      payload.merge!(defaults.transform_keys(&:to_s)) do |_key, existing, default|
        existing.presence || default
      end
    end

    def registration_form_schema
      @registration_form_schema ||= Registrations::FormSchema.new(@offering.metadata["registration_form"])
    end
    helper_method :registration_form_schema
  end
end
