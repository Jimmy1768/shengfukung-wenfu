#!/usr/bin/env ruby
# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../rails/Gemfile', __dir__)
require 'bundler/setup'

require 'yaml'
require 'json'
require_relative '../../rails/config/environment'
require_relative '../../rails/app/services/offerings/template_loader'
require_relative '../../rails/app/services/offerings/template_sync'

def resolve_selected_temple!
  slug = ENV["SLUG"].to_s.strip
  return nil if slug.blank?

  Temple.find_by(slug:) || abort("Unknown SLUG: #{slug}")
end

selected_temple = resolve_selected_temple!
scope = selected_temple ? [selected_temple] : Temple.all

scope.each do |temple|
  result = Offerings::TemplateSync.call(temple)
  next if result.updated_events.empty? && result.updated_services.empty?

  result.updated_events.each { |slug| puts "Updated events #{slug} for #{temple.slug}" }
  result.updated_services.each { |slug| puts "Updated services #{slug} for #{temple.slug}" }
end
