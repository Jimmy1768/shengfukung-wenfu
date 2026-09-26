# frozen_string_literal: true

module Registrations
  class FormSchema
    DEFAULT_SECTIONS = {
      order: %i[quantity unit_price_cents currency certificate_number],
      contact: %i[primary_contact phone email dependents_notes notes],
      logistics: %i[preferred_date preferred_slot arrival_window ceremony_location],
      ritual_metadata: %i[ancestor_placard_name dedication_message incense_option certificate_notes]
    }.freeze

    # How a field's previously-entered values may be reused on the patron's
    # NEXT registration for this same offering.
    #
    #   prefill           -- a durable fact; pre-populate it (e.g. ancestors)
    #   offer_as_options  -- remember, but make the admin choose afresh
    #   never             -- do not remember at all (e.g. a purchase decision)
    #
    # Declared per (offering, field) in the offering's own yml, because the
    # same canonical field legitimately differs across offerings and temples:
    # dedication_message is a temple-authored incense-item picker on one
    # Shengfukung offering and freeform blessing text on three others, under
    # one shared label.
    REUSE_POLICIES = %i[prefill offer_as_options never].freeze

    # Deliberately a CONSTANT, not derived from allow_multiple/options.
    # A shape-derived default couples reuse behavior to another field's
    # value, so flipping allow_multiple for an unrelated reason would move
    # policy with nobody deciding it should -- and nobody could read a yml
    # and know the behavior. The shape heuristic lives in the onboarding
    # generator (lib/tasks/offerings.rake), which writes explicit reuse:
    # keys into a new temple's yml instead.
    #
    # `offer_as_options` is the safe constant, not `never`.
    #
    # Only ONE policy can cause harm: a wrong `prefill` silently carries a
    # stale answer into a registration the temple then physically acts on.
    # `offer_as_options` eliminates that mode while still remembering, so an
    # undeclared field keeps rule 3's benefit ("don't make an admin ask the
    # same question again") -- the past answers are visible and selectable,
    # they are just never presented as this year's answer.
    #
    # `never` was tried first and rejected: it is maximally safe but silently
    # disables a shipped, working feature for every config not yet annotated,
    # trading a real benefit for protection against a mode `offer_as_options`
    # already prevents.
    DEFAULT_REUSE_POLICY = :offer_as_options

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

    def reuse_policy(field)
      config = field_settings[field.to_sym] || {}
      candidate = config[:reuse].presence&.to_sym
      REUSE_POLICIES.include?(candidate) ? candidate : DEFAULT_REUSE_POLICY
    end

    def reusable?(field)
      reuse_policy(field) != :never
    end

    def prefillable?(field)
      reuse_policy(field) == :prefill
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

    # Accepted shapes for a section, in the order a config is likely to use
    # them:
    #
    #   ritual_metadata: { fields: [a, b] }   -> exactly a and b
    #   ritual_metadata: [a, b]               -> exactly a and b (shorthand)
    #   ritual_metadata: false                -> section disabled
    #   ritual_metadata: a                    -> exactly a
    #   (absent) / nil / true                 -> the section's defaults
    #
    # The Hash form is the one every real temple yml uses, and it was NOT
    # handled until 2026-08-28: a Hash fell through to `else` and returned
    # the section's FULL default list, so offerings rendered fields they had
    # never declared. Tests did not catch it because they use the bare-Array
    # shorthand, which always worked -- the supported shape was exercised
    # while the shipped shape was silently ignored.
    #
    # A Hash carrying no `fields:` key still falls back to defaults: it is
    # declaring something else about the section, not declaring emptiness.
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
      when Hash
        declared = override[:fields]
        declared = override["fields"] if declared.nil?
        return default_fields if declared.nil?

        Array(declared).map(&:to_sym)
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
