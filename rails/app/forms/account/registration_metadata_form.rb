# frozen_string_literal: true

module Account
  class RegistrationMetadataForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    REGISTRANT_SCOPES = %w[self dependent].freeze

    attribute :quantity, :integer
    attribute :registrant_scope, :string
    attribute :dependent_id, :integer
    attribute :contact_name, :string
    attribute :contact_phone, :string
    attribute :contact_email, :string
    attribute :household_notes, :string
    attribute :arrival_window, :string
    attribute :ceremony_notes, :string

    validates :contact_name, presence: true, if: :contact_fields_editable?
    validates :registrant_scope, inclusion: { in: REGISTRANT_SCOPES }
    validates :quantity, numericality: { greater_than: 0, less_than_or_equal_to: 10 }, if: :core_fields_editable?
    validate :dependent_selection
    validate :duplicate_registration_guard

    attr_reader :registration, :user

    def initialize(registration:, user:, params: nil, lifecycle_policy: nil)
      @registration = registration
      @user = user
      @lifecycle_policy = lifecycle_policy
      attributes = defaults_from_registration.merge(filtered_params(params))
      super(attributes)
    end

    def save
      return false unless valid?

      registration.assign_attributes(
        contact_payload: merged_contact_payload,
        logistics_payload: merged_logistics_payload,
        metadata: merged_metadata
      )
      registration.quantity = quantity if core_fields_editable?
      registration.save!
    rescue ActiveRecord::RecordInvalid => e
      errors.merge!(e.record.errors)
      false
    end

    private

    def lifecycle_policy
      @lifecycle_policy ||= Registrations::LifecyclePolicy.new(registration)
    end

    def core_fields_editable?
      lifecycle_policy.core_fields_editable?
    end

    def contact_fields_editable?
      lifecycle_policy.contact_fields_editable?
    end

    def filtered_params(raw_params)
      params_hash = (raw_params.presence || {}).to_h
      params_hash = params_hash.except("quantity", "registrant_scope", "dependent_id", :quantity, :registrant_scope, :dependent_id) unless core_fields_editable?
      return params_hash if contact_fields_editable?

      params_hash.except(
        "contact_name", "contact_phone", "contact_email", "household_notes",
        :contact_name, :contact_phone, :contact_email, :household_notes
      )
    end

    def defaults_from_registration
      contact = registration.contact_payload || {}
      logistics = registration.logistics_payload || {}
      metadata = registration.metadata || {}
      {
        quantity: registration.quantity,
        registrant_scope: metadata["registrant_scope"].presence || "self",
        dependent_id: metadata["dependent_id"].presence,
        contact_name: contact["primary_contact"],
        contact_phone: contact["phone"],
        contact_email: contact["email"],
        household_notes: contact["dependents_notes"],
        arrival_window: logistics["arrival_window"],
        ceremony_notes: metadata["ceremony_notes"]
      }
    end

    def merged_contact_payload
      return registration.contact_payload || {} unless contact_fields_editable?

      (registration.contact_payload || {}).merge(
        "primary_contact" => contact_name,
        "phone" => contact_phone,
        "email" => contact_email,
        "dependents_notes" => household_notes
      ).compact_blank
    end

    def merged_logistics_payload
      (registration.logistics_payload || {}).merge(
        "arrival_window" => arrival_window
      ).compact_blank
    end

    def merged_metadata
      merged = (registration.metadata || {}).merge("ceremony_notes" => ceremony_notes).compact_blank
      return merged unless core_fields_editable?

      if dependent_selected?
        merged["registrant_scope"] = "dependent"
        merged["dependent_id"] = dependent_id.to_s
        merged["registrant_name"] = dependent&.english_name.presence || dependent&.native_name
      else
        merged["registrant_scope"] = "self"
        merged.delete("dependent_id")
        merged.delete("registrant_name")
      end
      merged
    end

    def dependent_selection
      return unless core_fields_editable?
      return unless registrant_scope == "dependent"

      errors.add(:dependent_id, :blank) unless dependent
    end

    def duplicate_registration_guard
      return unless core_fields_editable?
      return unless duplicate_registration_exists?

      errors.add(:base, I18n.t("account.registrations.new.duplicate_error", default: "You already have a registration for this offering."))
    end

    def duplicate_registration_exists?
      Registrations::ExistingLookup.new(
        scope: user.temple_event_registrations,
        offering: registration.registrable,
        user_id: user.id,
        registrant_scope: registrant_scope,
        dependent_id: dependent_id,
        excluding_id: registration.id
      ).find.present?
    end

    def dependent_selected?
      registrant_scope == "dependent" && dependent_id.present?
    end

    def dependent
      return @dependent if defined?(@dependent)

      @dependent = user.dependents.find_by(id: dependent_id)
    end
  end
end
