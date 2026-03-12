# frozen_string_literal: true

module Offerings
  class TemplateParity
    Result = Struct.new(
      :temple_slug,
      :missing_events,
      :missing_services,
      :orphaned_events,
      :orphaned_services,
      :created_events,
      :created_services,
      keyword_init: true
    )

    def self.report(temple)
      new(temple).report
    end

    def self.ensure_missing!(temple, kinds: %i[events services])
      new(temple).ensure_missing!(kinds: kinds)
    end

    def initialize(temple, loader: Offerings::TemplateLoader.new(temple.slug))
      @temple = temple
      @loader = loader
    end

    def report
      Result.new(
        temple_slug: temple.slug,
        missing_events: missing_slugs(loader.events, temple.temple_events),
        missing_services: missing_slugs(loader.services, temple.temple_services),
        orphaned_events: orphaned_slugs(loader.events, temple.temple_events),
        orphaned_services: orphaned_slugs(loader.services, temple.temple_services),
        created_events: [],
        created_services: []
      )
    end

    def ensure_missing!(kinds: %i[events services])
      result = report

      Array(kinds).map(&:to_sym).each do |kind|
        case kind
        when :events
          result.created_events = create_missing_events(result.missing_events)
        when :services
          result.created_services = create_missing_services(result.missing_services)
        end
      end

      result
    end

    private

    attr_reader :temple, :loader

    def missing_slugs(entries, scope)
      template_slugs = Array(entries).map { |entry| entry[:slug].to_s }
      existing_slugs = scope.pluck(:slug)
      template_slugs - existing_slugs
    end

    def orphaned_slugs(entries, scope)
      template_slugs = Array(entries).map { |entry| entry[:slug].to_s }
      existing_slugs = scope.pluck(:slug)
      existing_slugs - template_slugs
    end

    def create_missing_events(slugs)
      Array(slugs).filter_map do |slug|
        template = loader.template_for(slug, kind: :events)
        next unless template

        event = temple.temple_events.create!(build_event_attributes(template))
        event.slug
      end
    end

    def create_missing_services(slugs)
      Array(slugs).filter_map do |slug|
        template = loader.template_for(slug, kind: :services)
        next unless template

        service = temple.temple_services.create!(build_service_attributes(template))
        service.slug
      end
    end

    def build_event_attributes(template)
      {
        slug: template.fetch(:slug),
        title: template[:label].presence || template[:slug].to_s.titleize,
        description: template.dig(:attributes, :description),
        price_cents: template.dig(:attributes, :price_cents) || 0,
        currency: template.dig(:attributes, :currency).presence || "TWD",
        status: "draft",
        location_name: temple.name,
        location_address: default_location_address,
        metadata: template_metadata(template)
      }.compact
    end

    def build_service_attributes(template)
      registration_period_key = template[:registration_period_key].presence
      {
        slug: template.fetch(:slug),
        title: template[:label].presence || template[:slug].to_s.titleize,
        description: template.dig(:attributes, :description),
        price_cents: template.dig(:attributes, :price_cents) || 0,
        currency: template.dig(:attributes, :currency).presence || "TWD",
        status: "draft",
        default_location: default_location_address,
        registration_period_key:,
        period_label: period_label_for(registration_period_key),
        metadata: template_metadata(template)
      }.compact
    end

    def template_metadata(template)
      metadata = {}
      metadata["offering_type"] = template.dig(:defaults, :offering_type) if template.dig(:defaults, :offering_type)
      metadata["form_fields"] = template[:form_fields] if template[:form_fields]
      metadata["form_defaults"] = template[:defaults] if template[:defaults]
      metadata["form_options"] = template[:options] if template[:options]
      metadata["form_ui"] = template[:ui] if template[:ui]
      metadata["form_label"] = template[:label] if template[:label]
      metadata["registration_form"] = template[:registration_form] if template[:registration_form]
      unless template[:allow_repeat_registrations].nil?
        metadata["allow_repeat_registrations"] = template[:allow_repeat_registrations]
      end
      metadata
    end

    def default_location_address
      details = temple.contact_details || {}
      details["mapUrl"].presence || details["addressZh"].presence || details["addressEn"].presence
    end

    def period_label_for(key)
      return if key.blank?

      temple.registration_period_label_for(key)
    end
  end
end
