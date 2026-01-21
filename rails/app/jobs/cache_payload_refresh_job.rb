# frozen_string_literal: true

# app/jobs/cache_payload_refresh_job.rb
#
# Periodic job that scans for stale cache states and queues refresh workers.
class CachePayloadRefreshJob
  include Sidekiq::Job
  sidekiq_options queue: Profile::Infrastructure::JobQueues::SYSTEM_TASKS, retry: 3

  DEFAULT_BATCH_LIMIT = 100

  def perform(limit = DEFAULT_BATCH_LIMIT)
    ClientCacheState.stale.limit(limit).find_each do |state|
      Cache::CacheRefreshWorker.perform_async(state.id)
    end
  end
end
