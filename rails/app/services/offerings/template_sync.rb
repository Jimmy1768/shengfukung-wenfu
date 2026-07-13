# frozen_string_literal: true

module Offerings
  class TemplateSync
    Result = Struct.new(:temple_slug, :updated_events, :updated_services, keyword_init: true)

    def self.call(...)
      new(...).call
    end

    def initialize(temple, loader: Offerings::TemplateLoader.new(temple.slug))
      @temple = temple
      @loader = loader
    end

    def call
      Result.new(
        temple_slug: temple.slug,
        updated_events: sync_entries(loader.events, temple.temple_events),
        updated_services: sync_entries(loader.services, temple.temple_services)
      )
    end

    private

    attr_reader :temple, :loader

    def sync_entries(entries, scope)
      Array(entries).filter_map do |entry|
        offering = scope.find_by(slug: entry[:slug])
        next unless offering

        offering.metadata ||= {}
        offering.metadata["offering_type"] = entry.dig(:defaults, :offering_type) if entry.dig(:defaults, :offering_type)
        offering.metadata["form_fields"] = entry[:form_fields] if entry[:form_fields]
        offering.metadata["form_defaults"] = entry[:defaults] if entry[:defaults]
        offering.metadata["form_options"] = entry[:options] if entry[:options]
        offering.metadata["form_ui"] = entry[:ui] if entry[:ui]
        offering.metadata["form_label"] = entry[:label] if entry[:label]
        offering.metadata["registration_form"] = entry[:registration_form] if entry[:registration_form]
        offering.metadata["allow_repeat_registrations"] = entry[:allow_repeat_registrations] unless entry[:allow_repeat_registrations].nil?
        offering.save!
        offering.slug
      end
    end
  end
end
