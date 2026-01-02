# frozen_string_literal: true

module Notifications
  class AlertSmokeTestWorker
    include Sidekiq::Job
    sidekiq_options queue: Profile::Infrastructure::JobQueues::NOTIFICATIONS_ALERTS, retry: 5

    def perform
      Rails.logger.info "[Notifications::AlertSmokeTestWorker] Starting smoke test run"

      Notifications::Test::SidekiqTransientFailure.call
      Notifications::AlertSmokeTestFatalWorker.perform_async
      Notifications::Test::PushFailure.call
      Notifications::Test::EmailFailure.call

      Rails.logger.info "[Notifications::AlertSmokeTestWorker] Smoke test run completed"
    end
  end
end
