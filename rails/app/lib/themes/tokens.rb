# frozen_string_literal: true

require "json"

module Themes
  module Tokens
    CONFIG_PATH = Rails.root.join("..", "shared", "design-system", "themes.json").freeze
    RAW_CONFIG = JSON.parse(File.read(CONFIG_PATH))

    DEFAULT_KEY = RAW_CONFIG.fetch("defaultTheme")
    THEME_TOKENS = RAW_CONFIG.fetch("themes").transform_values do |theme|
      theme.fetch("tokens")
    end.freeze

    def self.for_theme(theme_id = DEFAULT_KEY)
      THEME_TOKENS[theme_id.to_s] || THEME_TOKENS[DEFAULT_KEY]
    end

    def self.fetch(theme_id, key)
      for_theme(theme_id).fetch(key.to_s) { for_theme(DEFAULT_KEY)[key.to_s] }
    end

    def self.default
      for_theme(DEFAULT_KEY)
    end

    def self.keys
      THEME_TOKENS.keys
    end
  end
end
