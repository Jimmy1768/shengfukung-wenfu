# app/lib/profile/identity.rb
#
# Profile::Identity
# ------------------------------------------------------------------
# Single source of truth for non-secret identity / naming decisions:
# - app codename (used in cookie names, Redis namespaces, etc.)
# - email identities (from/reply-to/support)
# - brand / company names
# - optional domain defaults
#
# All values here are safe to commit and can be edited per client
# when cloning the Golden Template.
#
module Profile
  module Identity
    # === APP CODENAME =======================================================
    #
    # Machine-friendly identifier for this project, used in:
    # - the session cookie name       (_<codename>_session)
    # - the Redis cache namespace     (<codename>_cache)
    # - the Redis app-state prefix    (<codename>:appstate)
    #
    # Derived from the project slug in shared/app_constants/project.json so two
    # projects cloned from this template never share a session cookie name or a
    # Redis namespace. It used to be the literal "initial" in every clone, which
    # meant siblings deployed on one Redis instance shared cache and app-state
    # keys, and siblings on sibling subdomains collided on session cookies. It
    # also looked like a real value rather than a placeholder, so nothing caught
    # it -- it matches no search for the template's name.
    #
    # This file is required directly from config/application.rb, before Rails
    # autoloading and Rails.root exist, so the shared config is read relative to
    # __dir__ rather than through AppConstants::Project.
    #
    # Override with APP_CODENAME when a deployment needs a name that is not the
    # slug (for example when renaming a project without invalidating sessions).
    #
    PROJECT_CONFIG_PATH = File.expand_path(
      "../../../../shared/app_constants/project.json", __dir__
    ).freeze

    def self.app_codename
      @app_codename ||= normalize_codename(configured_codename)
    end

    def self.configured_codename
      override = ENV["APP_CODENAME"]
      return override unless override.nil? || override.strip.empty?

      begin
        require "json"
        JSON.parse(File.read(PROJECT_CONFIG_PATH))["slug"]
      rescue StandardError
        nil
      end
    end

    def self.normalize_codename(value)
      normalized = value.to_s.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
      normalized.empty? ? "app" : normalized
    end

    # === EMAIL IDENTITY =====================================================
    #
    # Default sender/support emails for notifications. Non-secret.
    #

    DEFAULT_SENDER_NAME  = "TempleMate".freeze
    DEFAULT_SENDER_EMAIL = "no-reply@sourcegridlabs.com".freeze

    SUPPORT_EMAIL        = "admin@sourcegridlabs.com".freeze
    # BILLING_EMAIL      = "billing@example.com".freeze

    # === BRAND / COMPANY IDENTITY ===========================================
    #
    # Used for email footers, legal text, and generic non-localized labels.
    #

    APP_BRAND_NAME       = "TempleMate".freeze
    COMPANY_LEGAL_NAME   = "SourceGrid Labs".freeze
    COMPANY_DISPLAY_NAME = "SourceGrid Labs".freeze
    # COMPANY_ADDRESS_LINE_1 = "123 Example St".freeze
    # COMPANY_ADDRESS_LINE_2 = "City, Country".freeze

    # === DOMAIN DEFAULTS (OPTIONAL / LOCAL) =================================
    #
    # For production, prefer ENV:
    #   WEB_DOMAIN, API_DOMAIN, APP_DOMAIN, DEV_DOMAIN
    #
    # These constants are fallback defaults for local/simple setups.
    #

    DEFAULT_WEB_DOMAIN = "localhost".freeze
    DEFAULT_API_DOMAIN = "localhost".freeze
    DEFAULT_APP_DOMAIN = "localhost".freeze
    DEFAULT_DEV_DOMAIN = "localhost".freeze
  end
end
