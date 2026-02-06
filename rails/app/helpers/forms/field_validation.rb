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
      ].freeze
    }.freeze

    def required_fields(rule)
      DEFAULT_RULES.fetch(rule.to_sym) { [] }
    end

    def missing_fields(rule, attributes)
      attrs_hash = attributes.to_h
      required_fields(rule).each_with_object([]) do |field, missing|
        key =
          if attrs_hash.key?(field.to_s)
            field.to_s
          elsif attrs_hash.key?(field.to_sym)
            field.to_sym
          end
        next unless key

        value = attrs_hash[key]
        missing << field if value.blank?
      end
    end
  end
end
