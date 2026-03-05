require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require gems from Gemfile
Bundler.require(*Rails.groups)
require_relative "../app/lib/profile/identity"
require_relative "../app/middleware/api_protection/audit_middleware"

#
# IMPORTANT:
# Replace "Backend" with the **actual module name** of your backend folder.
# Since your Golden Template folder is called /backend, the module name is Backend.
#
module Backend
  class Application < Rails::Application
    # Initialize configuration defaults for Rails 7.1
    config.load_defaults 7.1

    # === Autoloading / Lib folders ==========================================
    # Rails 7.1 supports: config.autoload_lib(ignore: [...])
    config.autoload_lib(ignore: %w(assets tasks))

    # === API + HTML mode =====================================================
    # Enable the full middleware stack so HTML admin/account consoles work out
    # of the box (method override, CSRF, helpers, etc.) while API namespaces
    # can still opt into lightweight controllers.
    config.api_only = false
    config.session_store :cookie_store,
                         key: "_#{Profile::Identity.app_codename}_session",
                         secure: Rails.env.production?,
                         same_site: :lax

    config.middleware.use ApiProtection::AuditMiddleware

    # === Custom App Metadata (Golden Template) ===============================
    # This stores the codename for the project.
    # The clone/rename script will replace this automatically.
    config.x.app_codename = "initial"

    # === Locale / Timezone defaults =========================================
    # You will override or finalize later, but let's keep a clean template.
    # config.time_zone = "Asia/Taipei"
    config.i18n.default_locale = :"zh-TW"
    config.i18n.available_locales = %i[en zh-TW]

    # === Additional Paths (optional) ========================================
    config.autoload_paths << Rails.root.join("app/forms")
    config.autoload_paths << Rails.root.join("app/services")
    config.autoload_paths << Rails.root.join("app/middleware")
    config.eager_load_paths << Rails.root.join("app/lib")
    config.eager_load_paths << Rails.root.join("app/services")
    config.eager_load_paths << Rails.root.join("app/middleware")
  end
end
