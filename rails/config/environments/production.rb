# config/environments/production.rb

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # === Code loading & performance ===========================================

  # Cache classes and eager load code for maximum performance.
  config.cache_classes = true
  config.eager_load = true

  # Disable full error reports; use error pages instead.
  config.consider_all_requests_local       = false
  config.action_dispatch.show_exceptions   = true

  # === Caching ===============================================================

  # Enable controller-level caching.
  config.action_controller.perform_caching = true

  # Use Redis as cache store (prefer a dedicated REDIS_CACHE_URL,
  # or fall back to the appstate Redis).
  redis_cache_url = ENV["REDIS_CACHE_URL"] || ENV["REDIS_APPSTATE_URL"]
  if redis_cache_url.present?
    config.cache_store = :redis_cache_store, { url: redis_cache_url }
  else
    config.cache_store = :memory_store
  end

  # === Active Job / Sidekiq ==================================================

  # Sidekiq handles background jobs in production.
  config.active_job.queue_adapter = :sidekiq

  # === Action Mailer (Brevo API via service; no SMTP) =======================

  # Production still uses Action Mailer for generating email templates,
  # but actual sending is handled via Brevo HTTP API inside
  # Notifications::EmailService. We keep delivery_method :test so
  # ActionMailer itself doesn’t try to talk SMTP.
  config.action_mailer.delivery_method = :test
  config.action_mailer.perform_deliveries = false
  config.action_mailer.raise_delivery_errors = true

  web_host = ENV["WEB_DOMAIN"] || "example.com"
  config.action_mailer.default_url_options = {
    host: web_host,
    protocol: "https"
  }

  # === Static files / assets ================================================

  # Let Nginx or another reverse proxy serve static files in production.
  # Set RAILS_SERVE_STATIC_FILES in environments where Rails should do it.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Compress responses (you can tune this later).
  config.middleware.use Rack::Deflater

  # === Logging ===============================================================

  config.log_level = :info
  config.log_tags  = [:request_id]

  # Use STDOUT logging by default (Docker / systemd friendly).
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # === Action Cable (Realtime / WebSockets) =================================

  api_domain = ENV["API_DOMAIN"]
  if api_domain.present?
    config.action_cable.url = ENV["CABLE_URL"] || "wss://#{api_domain}/cable"
  end

  allowed_origins = []
  allowed_origins << "https://#{ENV["WEB_DOMAIN"]}" if ENV["WEB_DOMAIN"].present?
  allowed_origins << "https://#{ENV["APP_DOMAIN"]}" if ENV["APP_DOMAIN"].present?
  allowed_origins << "https://#{ENV["DEV_DOMAIN"]}" if ENV["DEV_DOMAIN"].present?

  config.action_cable.allowed_request_origins = allowed_origins unless allowed_origins.empty?
  config.action_cable.disable_request_forgery_protection = false

  # === SSL / Security =======================================================

  # If you terminate SSL at Nginx and forward X-Forwarded-Proto correctly,
  # you can enable this to force HTTPS-aware URLs and redirects.
  config.force_ssl = ENV["FORCE_SSL"].present?

  # === Internationalization / Timezone ======================================

  # Usually set in application.rb, repeated here as a reminder of defaults.
  # config.time_zone = "Asia/Taipei"
  # config.i18n.default_locale = :en
  # config.i18n.fallbacks = [:en]

  # === Misc ==================================================================

  # Don’t dump full schema on every deploy; adjust if needed.
  config.active_record.dump_schema_after_migration = false if config.respond_to?(:active_record)
end
