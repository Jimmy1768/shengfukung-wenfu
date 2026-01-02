# frozen_string_literal: true

module SystemTasks
  # Worker stub for orchestrating daily system maintenance jobs.
  class DailyTasks
    include Sidekiq::Worker
    sidekiq_options queue: Profile::Infrastructure::JobQueues::SYSTEM_TASKS, retry: false

    def perform
      # Soft delete, log rotation, billing cleanup, etc. should live in service objects.
    end
  end
end
