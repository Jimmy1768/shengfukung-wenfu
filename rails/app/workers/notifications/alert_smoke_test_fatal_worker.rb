# frozen_string_literal: true

module Notifications
  class AlertSmokeTestFatalWorker
    include Sidekiq::Job
    sidekiq_options queue: Profile::Infrastructure::JobQueues::NOTIFICATIONS_ALERTS, retry: 1

    def perform
      Notifications::Test::SidekiqFatalFailure.call
    end
  end
end
