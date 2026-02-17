# frozen_string_literal: true

module Account
  class RegistrationIntakeForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :quantity, :integer, default: 1
    attribute :contact_name, :string
    attribute :contact_phone, :string
    attribute :contact_email, :string
    attribute :household_notes, :string
    attribute :arrival_window, :string
    attribute :ceremony_notes, :string

    validates :quantity,
      numericality: { greater_than: 0, less_than_or_equal_to: 10 }
    validates :contact_name, presence: true

    attr_reader :registration, :offering, :user

    def initialize(user:, offering:, params: nil)
      @user = user
      @offering = offering
      attributes = params.presence || defaults_from_user
      super(attributes)
    end

    def save
      return false unless valid?

      ActiveRecord::Base.transaction do
        build_registration!
        update_user_metadata!
      end

      true
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:base, e.message)
      false
    end

    private

    def defaults_from_user
      metadata = user&.metadata || {}
      {
        contact_name: user&.english_name || metadata["contact_name"],
        contact_phone: metadata["phone"],
        contact_email: user&.email,
        household_notes: metadata["household_notes"]
      }.compact
    end

    def build_registration!
      price = offering.respond_to?(:price_cents) ? offering.price_cents.to_i : 0
      @registration = TempleEventRegistration.new(
        temple: offering.temple,
        registrable: offering,
        user: user,
        quantity: quantity,
        unit_price_cents: price,
        total_price_cents: price * quantity.to_i,
        currency: offering.respond_to?(:currency) ? offering.currency : "TWD",
        contact_payload: contact_payload,
        logistics_payload: logistics_payload,
        metadata: metadata_payload
      )
      @registration.event_slug = offering.slug if @registration.respond_to?(:event_slug=)
      @registration.save!
    end

    def contact_payload
      {
        "primary_contact" => contact_name,
        "phone" => contact_phone,
        "email" => contact_email,
        "dependents_notes" => household_notes
      }.compact_blank
    end

    def logistics_payload
      { "arrival_window" => arrival_window }.compact_blank
    end

    def metadata_payload
      payload = {}
      payload["ceremony_notes"] = ceremony_notes if ceremony_notes.present?
      if offering.respond_to?(:registration_period_key) && offering.registration_period_key.present?
        payload["registration_period_key"] = offering.registration_period_key
      end
      payload.compact_blank
    end

    def update_user_metadata!
      user_metadata = metadata_payload.except("registration_period_key")
      Registrations::UserMetadataUpdater.new(
        user:,
        offering_slug: offering.slug,
        contact_payload: contact_payload,
        logistics_payload: logistics_payload,
        ritual_metadata: user_metadata,
        order_details: {
          quantity: quantity,
          certificate_number: @registration&.certificate_number
        }
      ).update!
    end
  end
end
