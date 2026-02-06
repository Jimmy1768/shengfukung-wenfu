# frozen_string_literal: true

module Offerings
  class TemplateLoader
    CONFIG_DIR = Rails.root.join("db", "temples", "offerings").freeze

    def initialize(temple_slug)
      @temple_slug = temple_slug
    end

    def templates
      @templates ||= events + services
    end

    attr_reader :temple_slug

    def events
      @events ||= load_templates[:events]
    end

    def services
      @services ||= load_templates[:services]
    end

    def template_for(slug, kind: nil)
      list =
        case kind&.to_sym
        when :event, :events then events
        when :service, :services then services
        else templates
        end
      list.find { |entry| entry[:slug] == slug }
    end

    private

    def load_templates
      path = CONFIG_DIR.join("#{temple_slug}.yml")
      return { events: [], services: [] } unless File.exist?(path)

      raw = YAML.safe_load(File.read(path), permitted_classes: [Date, Time]) || {}
      events_entries = normalize_entries(raw["events"], kind: :event)
      services_entries = normalize_entries(raw["services"], kind: :service)
      if events_entries.empty? && services_entries.empty?
        legacy_entries = normalize_entries(raw["offerings"])
        services_entries = legacy_entries.select { |entry| entry[:kind] == :service }
        events_entries = legacy_entries.select { |entry| entry[:kind] != :service }
      end
      {
        events: events_entries,
        services: services_entries
      }
    rescue Psych::SyntaxError => e
      Rails.logger.error("[Offerings::TemplateLoader] Failed to parse #{path}: #{e.message}")
      { events: [], services: [] }
    end

    def normalize_entries(entries, kind: nil)
      Array(entries).map do |entry|
        data = entry.deep_symbolize_keys
        resolved_kind = (data[:kind] || kind || :event).to_sym
        data.merge(kind: resolved_kind)
      end
    end
  end
end
