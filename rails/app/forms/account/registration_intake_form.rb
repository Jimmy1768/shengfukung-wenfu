# frozen_string_literal: true

module Account
  class RegistrationIntakeForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :quantity, :integer, default: 1
    attribute :registrant_scope, :string, default: "self"
    attribute :dependent_id, :integer
    attribute :contact_name, :string
    attribute :contact_phone, :string
    attribute :contact_email, :string
    attribute :household_notes, :string
    attribute :arrival_window, :string
    attribute :ceremony_notes, :string

    REGISTRANT_SCOPES = %w[self dependent].freeze

    validates :quantity,
      numericality: { greater_than: 0, less_than_or_equal_to: 10 }
    validates :contact_name, presence: true
    validates :registrant_scope, inclusion: { in: REGISTRANT_SCOPES }
    validate :dependent_selection

    attr_reader :registration, :offering, :user

    def initialize(user:, offering:, params: nil)
      @user = user
      @offering = offering
      normalized_params = normalize_params(params)
      @contact_fields_provided = contact_fields_provided?(normalized_params)
      attributes = defaults_from_user.merge(normalized_params)
      super(attributes)
      apply_dependent_defaults
    end

    def save
      return false unless valid?

      if duplicate_registration_exists?
        errors.add(:base, I18n.t("account.registrations.new.duplicate_error", default: "You already have a registration for this offering."))
        return false
      end

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
        registrant_scope: "self",
        contact_name: user&.native_name.presence || user&.english_name || metadata["contact_name"],
        contact_phone: metadata["phone"],
        contact_email: user&.email,
        household_notes: metadata["household_notes"]
      }.compact
    end

    def normalize_params(params)
      return {} if params.blank?

      case params
      when ActionController::Parameters
        params.to_unsafe_h
      when Hash
        params
      else
        {}
      end.compact
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
      payload["registrant_scope"] = registrant_scope if registrant_scope.present?
      if dependent_selected?
        payload["dependent_id"] = dependent_id.to_s
        payload["registrant_name"] = dependent&.english_name
      end
      payload["ceremony_notes"] = ceremony_notes if ceremony_notes.present?
      if offering.respond_to?(:registration_period_key) && offering.registration_period_key.present?
        payload["registration_period_key"] = offering.registration_period_key
      end
      payload.compact_blank
    end

    def update_user_metadata!
      user_metadata = metadata_payload.except("registration_period_key")
      contact_sync_payload = dependent_selected? ? {} : contact_payload
      Registrations::UserMetadataUpdater.new(
        user:,
        offering_slug: offering.slug,
        contact_payload: contact_sync_payload,
        logistics_payload: logistics_payload,
        ritual_metadata: user_metadata,
        order_details: {
          quantity: quantity,
          certificate_number: @registration&.certificate_number
        }
      ).update!
      sync_dependent_profile! if dependent_selected?
    end

    def apply_dependent_defaults
      unless registrant_scope == "dependent"
        self.dependent_id = nil
        return
      end

      return unless (selected = dependent)
      return if @contact_fields_provided

      self.contact_name = selected.native_name.presence || selected.english_name
      dependent_metadata = selected.metadata || {}
      self.contact_phone = dependent_metadata["phone"]
      self.contact_email = dependent_metadata["email"]
      self.household_notes = dependent_metadata["notes"]
    end

    def contact_fields_provided?(params)
      %w[contact_name contact_phone contact_email household_notes].any? { |key| params.key?(key) }
    end

    def dependent_selection
      return unless registrant_scope == "dependent"

      errors.add(:dependent_id, :blank) unless dependent
    end

    def sync_dependent_profile!
      selected = dependent
      return unless selected

      payload = dependent_contact_payload
      return if payload.blank?

      updated_metadata = (selected.metadata || {}).merge(payload)
      return if updated_metadata == (selected.metadata || {})

      selected.update!(metadata: updated_metadata)
    end

    def dependent_contact_payload
      {
        "phone" => contact_phone.presence,
        "email" => contact_email.presence,
        "notes" => household_notes.presence
      }.compact
    end

    def dependent_selected?
      registrant_scope == "dependent" && dependent_id.present?
    end

    def dependent
      return @dependent if defined?(@dependent)

      @dependent = user&.dependents&.find_by(id: dependent_id)
    end

    def duplicate_registration_exists?
      return false unless user && offering

      scope = user.temple_event_registrations.where("metadata ->> 'event_slug' = ?", offering.slug)
      if offering.respond_to?(:registration_period_key) && offering.registration_period_key.present?
        scope = scope.where("metadata ->> 'registration_period_key' = ?", offering.registration_period_key)
      end
      if dependent_selected?
        scope = scope.where("metadata ->> 'dependent_id' = ?", dependent_id.to_s)
      else
        scope = scope.where("COALESCE(metadata ->> 'dependent_id', '') = ''")
      end
      scope.exists?
    end
  end
end
