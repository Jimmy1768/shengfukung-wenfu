
# app/workers/maintenance/cleanup_worker.rb
#
# Sidekiq worker for performing a small, idempotent cleanup task.
#
# Called by NightlyCleanupJob or other jobs to fan-out work.
module Maintenance
  class CleanupWorker
    include Sidekiq::Worker

    # @param resource_type [String]
    # @param resource_id [Integer]
    def perform(resource_type, resource_id)
      # TODO: perform a targeted cleanup operation using services.
      raise NotImplementedError, "Maintenance::CleanupWorker#perform is not implemented yet"
    end
  end
end
