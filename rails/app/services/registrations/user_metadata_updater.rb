# frozen_string_literal: true

module Registrations
  class UserMetadataUpdater
    TRANSIENT_KEY_PATTERN = /(date|time)\z/i
    CONTACT_MAPPINGS = {
      "phone" => "phone",
      "notes" => "notes"
    }.freeze

    def initialize(user:, offering_slug:, contact_payload:, logistics_payload:, ritual_metadata:, order_details:, multi_value_fields: [])
      @user = user
      @offering_slug = offering_slug
      @contact_payload = (contact_payload || {}).to_h
      @logistics_payload = (logistics_payload || {}).to_h
      @ritual_metadata = (ritual_metadata || {}).to_h
      @order_details = (order_details || {}).to_h
      @multi_value_fields = Array(multi_value_fields).map(&:to_s)
    end

    def update!
      return unless user

      metadata = (user.metadata || {}).deep_dup
      update_contact_metadata(metadata)
      update_offering_metadata(metadata)

      user.metadata = metadata
      user.save! if user.changed?
    end

    private

    attr_reader :user, :offering_slug, :contact_payload, :logistics_payload,
      :ritual_metadata, :order_details, :multi_value_fields

    def update_contact_metadata(metadata)
      CONTACT_MAPPINGS.each do |source, destination|
        value = contact_payload[source]
        next if value.blank?

        assign_value(metadata, destination, value, multi_value_fields.include?(source))
      end
    end

    def update_offering_metadata(metadata)
      return if offering_slug.blank?

      offerings = metadata["offerings"] ||= {}
      offering_data = offerings[offering_slug] ||= {}
      build_offering_payload.each do |key, value|
        assign_value(offering_data, key, value, multi_value_fields.include?(key))
      end
    end

    def build_offering_payload
      payload = {}
      filtered_logistics.each { |key, value| payload[key] = value }
      ritual_metadata.each { |key, value| payload[key.to_s] = value }
      payload["certificate_number"] = order_details[:certificate_number] if order_details[:certificate_number].present?
      payload["quantity"] = order_details[:quantity] if order_details[:quantity].present?
      payload.compact_blank
    end

    def filtered_logistics
      logistics_payload.each_with_object({}) do |(key, value), memo|
        next if key.to_s.match?(TRANSIENT_KEY_PATTERN)
        memo[key.to_s] = value
      end
    end

    def assign_value(container, key, value, multi_value)
      key = key.to_s
      if multi_value
        existing = Array(container[key]).reject(&:blank?)
        existing << value
        container[key] = existing.uniq
      else
        container[key] = value
      end
    end
  end
end
