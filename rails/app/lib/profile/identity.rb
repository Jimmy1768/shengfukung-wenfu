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
    # - cookie/session keys
    # - Redis namespaces
    # - log prefixes (if desired)
    #
    # The clone script should change this per client.
    #

    APP_CODENAME = "initial".freeze

    def self.app_codename
      APP_CODENAME
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
