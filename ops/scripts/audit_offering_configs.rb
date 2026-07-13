#!/usr/bin/env ruby
# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../rails/Gemfile", __dir__)
require "bundler/setup"

require_relative "../../rails/config/environment"
require_relative "../../rails/app/services/offerings/template_loader"
require_relative "../../rails/app/services/offerings/template_parity"

def resolve_selected_temple!
  slug = ENV["SLUG"].to_s.strip
  return nil if slug.blank?

  Temple.find_by(slug:) || abort("Unknown SLUG: #{slug}")
end

selected_temple = resolve_selected_temple!
scope = selected_temple ? [selected_temple] : Temple.all

scope.each do |temple|
  result = Offerings::TemplateParity.report(temple)
  next if [
    result.missing_events,
    result.missing_services,
    result.orphaned_events,
    result.orphaned_services
  ].all?(&:empty?)

  puts "Temple: #{temple.slug}"
  puts "  Missing events: #{result.missing_events.join(', ')}" if result.missing_events.any?
  puts "  Missing services: #{result.missing_services.join(', ')}" if result.missing_services.any?
  puts "  Orphaned events: #{result.orphaned_events.join(', ')}" if result.orphaned_events.any?
  puts "  Orphaned services: #{result.orphaned_services.join(', ')}" if result.orphaned_services.any?
end
