
# app/controllers/api/v1/theme_controller.rb
#
# Simple endpoint to expose the current theme palette as JSON
# for mobile / SPA frontends.
#
# GET /api/v1/theme
module Api
  module V1
    class ThemeController < Api::BaseController
      def show
        render json: {
          key: resolved_theme_key,
          palette: theme_palette
        }
      end

      private

      def resolved_theme_key
        if defined?(current_user) && current_user.respond_to?(:theme_key) && current_user.theme_key.present?
          current_user.theme_key
        else
          Themes::DEFAULT_KEY
        end
      end
    end
  end
end
