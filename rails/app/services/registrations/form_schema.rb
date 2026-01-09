# frozen_string_literal: true

module Registrations
  class FormSchema
    DEFAULT_SECTIONS = {
      order: %i[quantity unit_price_cents currency certificate_number],
      contact: %i[primary_contact phone email dependents_notes notes],
      logistics: %i[preferred_date preferred_slot arrival_window ceremony_location],
      ritual_metadata: %i[ancestor_placard_name dedication_message incense_option certificate_notes]
    }.freeze

    DEFAULT_DEFAULTS = {
      order: {
        quantity: 1
      }
    }.freeze

    attr_reader :sections, :defaults

    def initialize(config = nil)
      config = (config || {}).deep_symbolize_keys
      @sections = build_sections(config[:sections])
      @defaults = build_defaults(config[:defaults])
    end

    def fields_for(section)
      sections[section.to_sym] || []
    end

    def section?(section)
      fields_for(section).any?
    end

    def include_field?(section, field)
      fields_for(section).include?(field.to_sym)
    end

    def defaults_for(section)
      defaults[section.to_sym] || {}
    end

    private

    def build_sections(config)
      normalized = {}
      DEFAULT_SECTIONS.each do |section, default_fields|
        override = config&.fetch(section, :__missing__)
        normalized[section] = normalize_field_config(default_fields, override)
      end
      normalized
    end

    def normalize_field_config(default_fields, override)
      case override
      when :__missing__, nil, true
        default_fields
      when false
        []
      when String, Symbol
        [override.to_sym]
      when Array
        override.map(&:to_sym)
      else
        default_fields
      end
    end

    def build_defaults(config)
      defaults = DEFAULT_DEFAULTS.deep_dup
      config&.each do |section, values|
        defaults[section.to_sym] ||= {}
        defaults[section.to_sym].merge!(values.deep_symbolize_keys)
      end
      defaults
    end
  end
end
