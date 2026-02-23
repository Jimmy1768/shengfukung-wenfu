# frozen_string_literal: true

module Themes
  module Policy
    COOKIE_EXPIRY = 180.days

    SURFACE_CONFIG = {
      account: {
        cookie_key: "account_display_mode",
        i18n_scope: "account.theme_selector.options",
        modes: [
          { id: "standard", palette_key: "ops-standard" },
          { id: "dark", palette_key: "ops-dark" }
        ].freeze
      },
      admin: {
        cookie_key: "admin_display_mode",
        i18n_scope: "admin.theme_selector.options",
        modes: [
          { id: "standard", palette_key: "ops-standard" },
          { id: "dark", palette_key: "ops-dark" }
        ].freeze
      }
    }.freeze

    class << self
      def cookie_key(surface)
        config_for(surface).fetch(:cookie_key)
      end

      def mode_ids(surface)
        modes_for(surface).map { |mode| mode.fetch(:id) }
      end

      def options(surface, locale: I18n.locale)
        config = config_for(surface)
        mode_ids(surface).map do |mode_id|
          {
            id: mode_id,
            label: I18n.t("#{config[:i18n_scope]}.#{mode_id}", locale:, default: fallback_mode_label(mode_id))
          }
        end
      end

      def resolve_mode_id(surface:, requested: nil, cookie_value: nil)
        [requested, cookie_value, default_mode_id(surface)].compact.each do |candidate|
          return candidate.to_s if valid_mode_id?(surface, candidate)
        end

        default_mode_id(surface)
      end

      def palette_key_for(surface:, mode_id:)
        mode = modes_for(surface).find { |entry| entry.fetch(:id) == mode_id.to_s }
        mode&.fetch(:palette_key)
      end

      def resolve(surface:, requested_mode: nil, cookie_value: nil, project_default: AppConstants::Project.default_theme_key)
        mode_id = resolve_mode_id(surface:, requested: requested_mode, cookie_value:)
        palette_key = palette_key_for(surface:, mode_id:)
        palette_key ||= project_default.to_s if palette_allowed_for_surface?(surface, project_default)
        palette_key ||= modes_for(surface).first.fetch(:palette_key)

        { mode_id:, palette_key: }
      end

      private

      def config_for(surface)
        SURFACE_CONFIG.fetch(surface.to_sym)
      end

      def modes_for(surface)
        config_for(surface).fetch(:modes)
      end

      def default_mode_id(surface)
        modes_for(surface).first.fetch(:id)
      end

      def valid_mode_id?(surface, mode_id)
        mode_ids(surface).include?(mode_id.to_s)
      end

      def palette_allowed_for_surface?(surface, palette_key)
        modes_for(surface).any? { |entry| entry.fetch(:palette_key) == palette_key.to_s }
      end

      def fallback_mode_label(mode_id)
        mode_id.to_s.humanize
      end
    end
  end
end
