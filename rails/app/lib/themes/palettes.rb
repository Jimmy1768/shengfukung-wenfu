# frozen_string_literal: true

require "json"

module Themes
  module Palettes
    CONFIG_PATH = Rails.root.join("..", "shared", "design-system", "themes.json").freeze
    RAW_CONFIG = JSON.parse(File.read(CONFIG_PATH))

    DEFAULT_KEY = RAW_CONFIG.fetch("defaultTheme").freeze

    PALETTES = RAW_CONFIG.fetch("themes").transform_values do |theme|
      tokens = theme.fetch("tokens")

      {
        bg: tokens.fetch("surface"),
        surface: tokens.fetch("surfaceRaised"),
        surface_muted: tokens.fetch("surfaceMuted"),
        border: tokens.fetch("border"),
        text: tokens.fetch("text"),
        text_muted: tokens.fetch("textMuted"),
        accent: tokens.fetch("accent"),
        accent_soft: tokens.fetch("surfaceMuted"),
        danger: tokens.fetch("danger"),
        success: tokens.fetch("success"),
        warning: tokens.fetch("warning"),
        primary: tokens.fetch("primary"),
        primary_foreground: tokens.fetch("primaryForeground")
      }.freeze
    end.freeze

    def self.for(key)
      string_key = key.to_s
      PALETTES[string_key] || PALETTES[DEFAULT_KEY]
    end

  end

  PALETTES = Palettes::PALETTES
  DEFAULT_KEY = Palettes::DEFAULT_KEY

  def self.for(key)
    Palettes.for(key)
  end
end
