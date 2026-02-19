# frozen_string_literal: true

module Registrations
  class LifecyclePolicy
    def self.core_fields_editable?(registration)
      new(registration).core_fields_editable?
    end

    def self.metadata_fields_editable?(registration)
      new(registration).metadata_fields_editable?
    end

    def self.gathering_editable?(registration)
      new(registration).gathering_editable?
    end

    attr_reader :registration

    def initialize(registration)
      @registration = registration
    end

    def core_fields_editable?
      return false unless registration.present?
      return false unless gathering_editable?

      !payment_recorded?
    end
    alias editable_core_fields? core_fields_editable?

    def metadata_fields_editable?
      return false unless registration.present?

      gathering_editable?
    end
    alias editable_metadata_fields? metadata_fields_editable?

    def gathering_editable?
      return false unless registration.present?
      return true unless gathering_registration?

      registration.new_record?
    end

    def payment_recorded?
      return false unless registration.present? && registration.persisted?

      @payment_recorded = registration.temple_payments.exists? if @payment_recorded.nil?
      @payment_recorded
    end

    private

    def gathering_registration?
      registration.registrable_type == TempleGathering.name
    end
  end
end
