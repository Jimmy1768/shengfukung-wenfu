# frozen_string_literal: true

module Offerings
  class TemplateLoader
    CONFIG_DIR = Rails.root.join("db", "temples", "offerings").freeze

    def initialize(temple_slug)
      @temple_slug = temple_slug
    end

    def templates
      @templates ||= load_templates
    end

    def template_for(slug)
      templates.find { |entry| entry[:slug] == slug }
    end

    private

    attr_reader :temple_slug

    def load_templates
      path = CONFIG_DIR.join("#{temple_slug}.yml")
      return [] unless File.exist?(path)

      raw = YAML.safe_load(File.read(path), permitted_classes: [Date, Time]) || {}
      Array(raw["offerings"]).map do |entry|
        entry.deep_symbolize_keys
      end
    rescue Psych::SyntaxError => e
      Rails.logger.error("[Offerings::TemplateLoader] Failed to parse #{path}: #{e.message}")
      []
    end
  end
end
