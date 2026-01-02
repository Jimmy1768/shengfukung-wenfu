# config/environments/development.rb

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # === Code loading & reloading =============================================

  # Reload code on every request. Slower, but perfect for development.
  config.cache_classes = false
  config.eager_load = false

  # Show full error reports in the browser.
  config.consider_all_requests_local = true

  # === Caching ===============================================================

  # Disable caching by default in development.
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # === Active Storage (not heavily used; you have custom S3Service) =========

  # If you decide to use Active Storage later, you can set:
  # config.active_storage.service = :local

  # === Active Job / Sidekiq ==================================================

  # Use Sidekiq for background jobs in dev so behavior matches production.
  config.active_job.queue_adapter = :sidekiq

  # === Action Mailer (Brevo API via service; no SMTP) =======================

  # In this template, real sending is done via Brevo HTTP API in
  # Notifications::EmailService (not via SMTP). Action Mailer is mainly
  # used for generating email bodies and previews.
  #
  # You can use :letter_opener if you like, or just :test / :file.
  config.action_mailer.delivery_method = :test
  config.action_mailer.perform_deliveries = false
  config.action_mailer.raise_delivery_errors = false

  # Host for URL helpers inside emails (password reset links, etc.).
  config.action_mailer.default_url_options = {
    host: ENV.fetch("WEB_DOMAIN", "localhost"),
    port: 3000
  }

  # === Static files / assets ================================================

  # Serve static files directly in development.
  config.public_file_server.enabled = true

  # === Logging ===============================================================

  config.log_level = :debug
  config.log_tags  = [:request_id]

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true if config.respond_to?(:active_record)

  # === Action Cable (Realtime / WebSockets) =================================

  # Local Action Cable endpoint.
  config.action_cable.url = "ws://localhost:3000/cable"

  # Allow connections from localhost.
  config.action_cable.allowed_request_origins = [
    %r{\Ahttp://localhost:\d+\z},
    %r{\Ahttp://127\.0\.0\.1:\d+\z}
  ]

  # Looser protection is acceptable in dev.
  config.action_cable.disable_request_forgery_protection = true

  # === Internationalization / Timezone ======================================

  # These are often set in config/application.rb; kept here as documentation
  # of the expected defaults for the template.
  # config.time_zone = "Asia/Taipei"
  # config.i18n.default_locale = :en
  # config.i18n.fallbacks = true

  # === Misc ==================================================================

  # Don’t care if assets are missing in dev.
  config.assets.raise_runtime_errors = false if config.respond_to?(:assets)
end
