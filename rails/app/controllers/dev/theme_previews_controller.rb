# frozen_string_literal: true

module Dev
  class ThemePreviewsController < ActionController::Base
    protect_from_forgery with: :null_session

    def create
      unless allow_override?
        head :forbidden
        return
      end

      theme = resolve_theme_key(params[:theme_key])
      cookies[:temple_theme] = {
        value: theme,
        expires: 1.day.from_now,
        path: "/"
      }

      respond_to do |format|
        format.html do
          redirect_back fallback_location: account_dashboard_path, notice: "Theme switched to #{theme}."
        end
        format.json { render json: { theme: theme } }
      end
    end

    private

    def allow_override?
      Rails.env.development?
    end

    def resolve_theme_key(value)
      key = value.to_s
      Themes::PALETTES.key?(key) ? key : Themes::DEFAULT_KEY
    end
  end
end
