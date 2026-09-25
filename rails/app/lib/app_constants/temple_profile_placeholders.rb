# frozen_string_literal: true

require "json"

module AppConstants
  # Only the hero image remains. This module used to hold contact,
  # service_times, visit_info and about defaults, which TempleSerializer
  # returned for any temple that had written nothing -- so the public API, and
  # then the public site, carried instructions addressed to an admin. Removed
  # 2026-09-25: a temple with no data now returns nothing and the site hides the
  # region, which is the only way a default can be safe when it is shown to
  # someone who cannot act on it.
  module TempleProfilePlaceholders
    CONFIG_PATH =
      Rails.root.join("..", "shared", "app_constants", "temple_profile_placeholders.json").freeze
    RAW_CONFIG = JSON.parse(File.read(CONFIG_PATH))

    HERO_IMAGES = RAW_CONFIG.fetch("hero_images", {}).freeze

    # The image a temple shows when a hero tab has none of its own. Lives in
    # the shared JSON so Rails and Vue read one value -- as a Ruby-only
    # constant the frontend could not see it, which is why siteContent.js grew
    # its own copy of the fallback chain.
    def self.default_hero_image
      HERO_IMAGES.fetch("default")
    end
  end
end
