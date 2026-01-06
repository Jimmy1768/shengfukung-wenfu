# frozen_string_literal: true

module Account
  class RegistrationMetadataForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :contact_name, :string
    attribute :contact_phone, :string
    attribute :contact_email, :string
    attribute :household_notes, :string
    attribute :arrival_window, :string
    attribute :ceremony_notes, :string

    validates :contact_name, presence: true

    attr_reader :registration

    def initialize(registration:, params: nil)
      @registration = registration
      attributes = params.presence || defaults_from_registration
      super(attributes)
    end

    def save
      return false unless valid?

      registration.update!(
        contact_payload: merged_contact_payload,
        logistics_payload: merged_logistics_payload,
        metadata: merged_metadata
      )
    rescue ActiveRecord::RecordInvalid => e
      errors.merge!(e.record.errors)
      false
    end

    private

    def defaults_from_registration
      contact = registration.contact_payload || {}
      logistics = registration.logistics_payload || {}
      metadata = registration.metadata || {}
      {
        contact_name: contact["primary_contact"],
        contact_phone: contact["phone"],
        contact_email: contact["email"],
        household_notes: contact["dependents_notes"],
        arrival_window: logistics["arrival_window"],
        ceremony_notes: metadata["ceremony_notes"]
      }
    end

    def merged_contact_payload
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
      (registration.metadata || {}).merge(
        "ceremony_notes" => ceremony_notes
      ).compact_blank
    end
  end
end
