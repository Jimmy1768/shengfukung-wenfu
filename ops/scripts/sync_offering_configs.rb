#!/usr/bin/env ruby
# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../rails/Gemfile', __dir__)
require 'bundler/setup'

require 'yaml'
require 'json'
require_relative '../../rails/config/environment'
require_relative '../../rails/app/services/offerings/template_loader'

Temple.find_each do |temple|
  loader = Offerings::TemplateLoader.new(temple.slug)
  next if loader.templates.empty?

  { events: loader.events, services: loader.services }.each do |kind, entries|
    scope = kind == :services ? temple.temple_services : temple.temple_events
    entries.each do |entry|
      offering = scope.find_by(slug: entry[:slug])
      next unless offering

      offering.metadata ||= {}
      offering.metadata['offering_type'] = entry.dig(:defaults, :offering_type) if entry.dig(:defaults, :offering_type)
      offering.metadata['form_fields'] = entry[:form_fields] if entry[:form_fields]
      offering.metadata['form_defaults'] = entry[:defaults] if entry[:defaults]
      offering.metadata['form_options'] = entry[:options] if entry[:options]
      offering.metadata['form_label'] = entry[:label] if entry[:label]
      offering.metadata['registration_form'] = entry[:registration_form] if entry[:registration_form]
      offering.save!
      puts "Updated #{kind} #{offering.slug} for #{temple.slug}"
    end
  end
end
