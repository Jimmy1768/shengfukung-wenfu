# frozen_string_literal: true

require "json"
require Rails.root.join("app", "lib", "themes", "palettes")

module AppConstants
  module Project
    CONFIG_PATH = Rails.root.join("..", "shared", "app_constants", "project.json").freeze
    RAW_CONFIG = JSON.parse(File.read(CONFIG_PATH))

    DEFAULT_SLUG = RAW_CONFIG.fetch("slug", "golden-template").freeze
    DEFAULT_NAME = RAW_CONFIG.fetch("name", "Golden Template").freeze
    DEFAULT_COMPANY_NAME = RAW_CONFIG.fetch("companyName", "SourceGrid Labs").freeze
    DEFAULT_MARKETING_ROOT = RAW_CONFIG.fetch("marketingRoot", "/var/www/#{DEFAULT_SLUG}")
    DEFAULT_SYSTEMD_ENV_DIR = RAW_CONFIG.fetch("systemdEnvDir", "/etc/default")
    DEFAULT_THEME_KEY = RAW_CONFIG.fetch("defaultThemeKey", Themes::DEFAULT_KEY)

    SLUG = ENV.fetch("PROJECT_SLUG", DEFAULT_SLUG).freeze
    NAME = ENV.fetch("PROJECT_NAME", DEFAULT_NAME).freeze
    COMPANY_NAME = ENV.fetch("PROJECT_COMPANY_NAME", DEFAULT_COMPANY_NAME).freeze
    MARKETING_ROOT = ENV.fetch("PROJECT_MARKETING_ROOT", DEFAULT_MARKETING_ROOT).freeze
    SYSTEMD_ENV_DIR = ENV.fetch("PROJECT_SYSTEMD_ENV_DIR", DEFAULT_SYSTEMD_ENV_DIR).freeze

    def self.slug
      SLUG
    end

    def self.name
      NAME
    end

    def self.company_name
      COMPANY_NAME
    end

    def self.systemd_env_file
      ENV.fetch("PROJECT_SYSTEMD_ENV_FILE") do
        File.join(SYSTEMD_ENV_DIR, "#{SLUG}-env")
      end
    end

    def self.marketing_root
      MARKETING_ROOT
    end

    def self.puma_service_name
      "#{SLUG}.service"
    end

    def self.sidekiq_service_name
      "#{SLUG}-sidekiq.service"
    end

    def self.nginx_config_filename
      "#{SLUG}.conf"
    end

    def self.default_theme_key
      ENV.fetch("PROJECT_DEFAULT_THEME_KEY", DEFAULT_THEME_KEY)
    end
  end
end
