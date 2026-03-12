#!/usr/bin/env ruby
# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../rails/Gemfile", __dir__)
require "bundler/setup"

require_relative "../../rails/config/environment"
require_relative "../../rails/app/services/offerings/template_loader"
require_relative "../../rails/app/services/offerings/template_parity"

slug = ENV["SLUG"].to_s
abort "Set SLUG=<temple-slug>" if slug.blank?

temple = Temple.find_by!(slug: slug)
result = Offerings::TemplateParity.ensure_missing!(temple)

puts "Temple: #{temple.slug}"
puts "  Created events: #{result.created_events.join(', ')}" if result.created_events.any?
puts "  Created services: #{result.created_services.join(', ')}" if result.created_services.any?
puts "  No missing template-backed offerings." if result.created_events.empty? && result.created_services.empty?
