# frozen_string_literal: true

module Admin
  class OfferingOrdersController < BaseController
    before_action :require_manage_registrations!
    before_action :set_offering_kind
    before_action :set_offering
    before_action :set_registration, only: %i[show edit update]
    before_action :redirect_gathering_edits!, only: %i[edit update]

    def index
      scope = @offering.temple_event_registrations
      @registrations = scope.recent
      @registrations_total = scope.count
      @registrations_paid = scope.with_status(TempleEventRegistration::PAYMENT_STATUSES[:paid]).count
      @registrations_pending = scope
        .with_status(TempleEventRegistration::PAYMENT_STATUSES[:pending])
        .where("total_price_cents > 0")
        .count
      @registrations_total_amount_cents = scope.sum(:total_price_cents)
    end

    def new
      @registration = @offering.temple_event_registrations.new(quantity: 1)
      prepare_registration_payloads
      apply_registration_defaults
      prepare_lifecycle_flags
    end

    def create
      attrs = registration_params
      normalize_registrant_selection!(attrs)

      if (existing = existing_registration_for(attrs))
        redirect_to offering_order_path(@offering, existing), notice: "Existing registration found. Redirected to edit."
        return
      end

      builder = Payments::TempleRegistrationBuilder.new(
        temple: current_temple,
        offering: @offering,
        admin_user: current_admin,
        attributes: attrs
      )

      @registration = builder.create
      redirect_to offering_order_path(@offering, @registration), notice: "Registration created."
    rescue ActiveRecord::RecordInvalid => e
      @registration = e.record
      prepare_registration_payloads
      apply_registration_defaults
      prepare_lifecycle_flags
      render :new, status: :unprocessable_entity
    end

    def show; end

    def edit
      prepare_registration_payloads
      prepare_lifecycle_flags
      render :new
    end

    def update
      attrs = policy_filtered_update_attributes(registration_params)
      normalize_registrant_selection!(attrs) if registration_lifecycle_policy.core_fields_editable?
      prepare_lifecycle_flags

      if registration_lifecycle_policy.core_fields_editable? &&
          (existing = existing_registration_for(attrs, excluding_id: @registration.id))
        redirect_to offering_order_path(@offering, existing), alert: "A matching registration already exists for this registrant."
        return
      end

      merged_metadata = merge_payload(@registration.metadata, attrs.delete(:metadata))
      merged_metadata["registration_period_key"] ||= @registration.metadata.to_h["registration_period_key"]

      @registration.assign_attributes(
        attrs.except(:contact_payload, :logistics_payload, :multi_value_fields).merge(
          contact_payload: merge_payload(@registration.contact_payload, attrs[:contact_payload]),
          logistics_payload: merge_payload(@registration.logistics_payload, attrs[:logistics_payload]),
          metadata: merged_metadata,
          event_slug: attrs[:event_slug].presence || @registration.event_slug || @offering.slug
        )
      )
      @registration.save!

      redirect_to offering_order_path(@offering, @registration), notice: "Registration updated."
    rescue ActiveRecord::RecordInvalid => e
      @registration = e.record
      prepare_registration_payloads
      prepare_lifecycle_flags
      render :new, status: :unprocessable_entity
    end

    private

    def set_offering_kind
      @offering_kind = params[:offering_kind]&.to_sym
      @offering_kind = :events unless %i[events services gatherings].include?(@offering_kind)
    end

    def set_offering
      @offering =
        case @offering_kind
        when :services
          current_temple.temple_services.find(offering_id_param)
        when :gatherings
          current_temple.temple_gatherings.find(offering_id_param)
        else
          current_temple.temple_events.find(offering_id_param)
        end
    end

    def set_registration
      @registration = @offering.temple_event_registrations.find(params[:id])
    end

    def redirect_gathering_edits!
      return if registration_lifecycle_policy.gathering_editable?

      redirect_to offering_order_path(@offering, @registration), alert: "Gathering attendance entries are read-only after creation."
    end

    def require_manage_registrations!
      require_capability!(:manage_registrations)
    end

    def registration_params
      permitted = ActionController::Parameters.new(merged_registration_param_payload).permit(
        :user_id,
        :quantity,
        :unit_price_cents,
        :currency,
        :certificate_number,
        :event_slug,
        :registrant_scope,
        :dependent_id,
        { multi_value_fields: [] },
        contact_details: %i[primary_contact email phone dependents_notes notes],
        logistics_details: %i[preferred_date preferred_slot arrival_window ceremony_location],
        ritual_metadata: %i[ancestor_placard_name dedication_message incense_option certificate_notes]
      )
      multi_fields = permitted.delete(:multi_value_fields)
      permitted[:multi_value_fields] = Array(multi_fields).map(&:to_s)
      permitted[:contact_payload] = sanitize_payload(permitted.delete(:contact_details))
      permitted[:logistics_payload] = sanitize_payload(permitted.delete(:logistics_details))
      metadata_fields = sanitize_payload(permitted.delete(:ritual_metadata))
      permitted[:metadata] = metadata_fields
      permitted.to_h
    end

    def merged_registration_param_payload
      payload = {}

      %i[temple_registration temple_event_registration].each do |key|
        raw = params[key]
        next if raw.blank?

        payload.deep_merge!(normalize_payload(raw))
      end

      payload
    end

    def sanitize_payload(raw_hash)
      return {} if raw_hash.blank?

      normalize_payload(raw_hash)
        .transform_values { |value| value.is_a?(String) ? value.strip : value }
        .compact_blank
    end

    def merge_payload(existing, incoming)
      normalize_payload(existing).merge(normalize_payload(incoming))
    end

    def normalize_payload(raw_payload)
      return {} if raw_payload.blank?
      return raw_payload.to_unsafe_h if raw_payload.is_a?(ActionController::Parameters)

      raw_payload.to_h
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

    def normalize_registrant_selection!(attrs)
      user = User.find_by(id: attrs[:user_id])
      scope = attrs.delete(:registrant_scope).to_s
      dependent_id = attrs.delete(:dependent_id).presence
      metadata = merge_payload({}, attrs[:metadata])

      if scope == "dependent" || dependent_id.present?
        dependent = resolve_dependent_for(user, dependent_id)
        unless dependent
          invalid = TempleEventRegistration.new
          invalid.errors.add(:base, "Dependent selection is invalid for selected patron.")
          raise ActiveRecord::RecordInvalid, invalid
        end

        metadata["registrant_scope"] = "dependent"
        metadata["dependent_id"] = dependent.id.to_s
        metadata["registrant_name"] = dependent.english_name.presence || dependent.native_name
      else
        metadata["registrant_scope"] = "self"
        metadata.delete("dependent_id")
        metadata.delete("registrant_name")
      end

      attrs[:metadata] = metadata
    end

    def resolve_dependent_for(user, dependent_id)
      return nil if user.blank? || dependent_id.blank?

      user.dependents.find_by(id: dependent_id)
    end

    def existing_registration_for(attrs, excluding_id: nil)
      Registrations::ExistingLookup.new(
        scope: @offering.temple_event_registrations,
        offering: @offering,
        user_id: attrs[:user_id],
        registrant_scope: attrs.dig(:metadata, "registrant_scope"),
        dependent_id: attrs.dig(:metadata, "dependent_id"),
        excluding_id:
      ).find
    end

    def policy_filtered_update_attributes(attrs)
      return attrs if registration_lifecycle_policy.core_fields_editable?

      immutable = %i[user_id quantity unit_price_cents currency registrant_scope dependent_id]
      sanitized = attrs.except(*immutable)
      sanitized = sanitized.except(:contact_payload) unless registration_lifecycle_policy.contact_fields_editable?
      metadata = merge_payload({}, sanitized[:metadata])
      metadata.except!("registrant_scope", "dependent_id", "registrant_name")
      sanitized[:metadata] = metadata
      sanitized
    end

    def prepare_lifecycle_flags
      @core_fields_editable = registration_lifecycle_policy.core_fields_editable?
      @metadata_fields_editable = registration_lifecycle_policy.metadata_fields_editable?
      @contact_fields_editable = registration_lifecycle_policy.contact_fields_editable?
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

    def registration_lifecycle_policy
      @registration_lifecycle_policy ||= Registrations::LifecyclePolicy.new(@registration)
    end
    helper_method :registration_lifecycle_policy

    def offering_order_path(offering, registration)
      case offering
      when TempleService
        admin_service_offering_order_path(offering, registration)
      when TempleGathering
        admin_gathering_offering_order_path(offering, registration)
      else
        admin_event_offering_order_path(offering, registration)
      end
    end

    def offering_id_param
      params[:offering_id] || params[:event_id] || params[:service_id] || params[:gathering_id]
    end
  end
end
