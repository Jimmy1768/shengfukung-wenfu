if defined?(Sidekiq)
  require Rails.root.join("app", "services", "notifications", "alerts", "sidekiq_failure_handler").to_s

  Sidekiq.configure_server do |config|
    config.error_handlers << proc do |exception, context|
      Notifications::Alerts::SidekiqFailureHandler.call(exception, context)
    end
  end
end
