# frozen_string_literal: true

require "json"

module AppConstants
  module TempleProfilePlaceholders
    CONFIG_PATH =
      Rails.root.join("..", "shared", "app_constants", "temple_profile_placeholders.json").freeze
    RAW_CONFIG = JSON.parse(File.read(CONFIG_PATH))

    CONTACT = RAW_CONFIG.fetch("contact", {}).freeze
    SERVICE_TIMES = RAW_CONFIG.fetch("service_times", {}).freeze
    VISIT_INFO = RAW_CONFIG.fetch("visit_info", {}).freeze
    ABOUT = RAW_CONFIG.fetch("about", {}).freeze

    def self.contact
      CONTACT
    end

    def self.service_times
      SERVICE_TIMES
    end

    def self.visit_info
      VISIT_INFO
    end

    def self.about
      ABOUT
    end
  end
end
