# frozen_string_literal: true

module Forms
  module FieldValidation
    extend self

    DEFAULT_RULES = {
      offering: %i[
        offering_type
        title
        description
        price_cents
        currency
        period
        starts_on
        ends_on
        available_slots
        active
      ].freeze
    }.freeze

    def required_fields(rule)
      DEFAULT_RULES.fetch(rule.to_sym) { [] }
    end

    def missing_fields(rule, attributes)
      attrs_hash = attributes.to_h
      required_fields(rule).each_with_object([]) do |field, missing|
        value = attrs_hash[field.to_s] || attrs_hash[field.to_sym]
        missing << field if value.blank?
      end
    end
  end
end
