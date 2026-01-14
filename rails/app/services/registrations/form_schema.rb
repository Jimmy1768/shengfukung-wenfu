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

    attr_reader :sections, :defaults, :field_settings

    def initialize(config = nil)
      config = (config || {}).deep_symbolize_keys
      @sections = build_sections(config[:sections])
      @defaults = build_defaults(config[:defaults])
      @field_settings = build_field_settings(config[:field_settings])
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

    def field_options(field)
      config = field_settings[field.to_sym] || {}
      normalize_options(config[:options])
    end

    def allow_multiple?(field)
      config = field_settings[field.to_sym] || {}
      config[:allow_multiple].present?
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

    def build_field_settings(config)
      return {} if config.blank?

      config.each_with_object({}) do |(field, settings), memo|
        memo[field.to_sym] = normalize_field_settings(settings)
      end
    end

    def normalize_field_settings(settings)
      case settings
      when Hash
        settings.deep_symbolize_keys
      when Array
        { options: settings }
      else
        {}
      end
    end

    def normalize_options(options)
      return [] if options.blank?

      case options
      when Hash
        options.map { |value, label| [label, value] }
      else
        Array(options).map { |value| [value, value] }
      end
    end
  end
end
