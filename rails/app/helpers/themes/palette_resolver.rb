# frozen_string_literal: true

# app/helpers/themes/palette.rb
# Exposes palette resolution helpers under the `Themes` namespace.
module Themes
  module PaletteResolver
    # Returns the palette hash for the current user (or the default palette).
    # Checks current_user.theme_key when available, otherwise falls back to Themes::DEFAULT_KEY.
    def theme_palette
      key =
        if defined?(current_user) && current_user.respond_to?(:theme_key)
          current_user.theme_key.presence
        else
          nil
        end

      Themes.for(key || Themes::DEFAULT_KEY)
    end
  end
end
