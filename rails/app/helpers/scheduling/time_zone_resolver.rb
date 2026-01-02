# frozen_string_literal: true

# app/helpers/scheduling/time_zone_resolver.rb
require "active_support/time"
#
# Central helper for working with time zone names/objects when building
# scheduling instructions. Cron-based jobs can rely on this to turn user- or
# system-provided values into valid ActiveSupport::TimeZone names before
# handing the value to Scheduling::RunTime.
module Scheduling
  module TimeZoneResolver
    DEFAULT_ZONE_NAME = "UTC".freeze

    def self.zone_name(candidate = nil)
      return DEFAULT_ZONE_NAME if candidate.nil?

      name =
        if candidate.respond_to?(:name)
          candidate.name
        else
          candidate.to_s
        end

      name = name.strip
      return DEFAULT_ZONE_NAME if name.empty?

      name
    end

    def self.active_zone(candidate = nil)
      ActiveSupport::TimeZone[zone_name(candidate)] || ActiveSupport::TimeZone[DEFAULT_ZONE_NAME]
    end
  end
end
