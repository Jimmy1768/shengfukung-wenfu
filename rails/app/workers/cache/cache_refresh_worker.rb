# frozen_string_literal: true

# app/workers/cache/cache_refresh_worker.rb
#
# Worker that rebuilds a single cache payload state in the background.
module Cache
  class CacheRefreshWorker
    include Sidekiq::Worker
    sidekiq_options queue: Profile::Infrastructure::JobQueues::SYSTEM_TASKS, retry: 3

    def perform(client_cache_state_id, options = {})
      state = ClientCacheState.find(client_cache_state_id)
      CachePayloads::Refresher.call(
        state_key: state.state_key,
        user: state.user,
        client_checkin: state.client_checkin,
        options: deep_symbolize(options.presence || state.metadata)
      )
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn("CacheRefreshWorker: state #{client_cache_state_id} no longer exists")
    end

    private

    def deep_symbolize(hash)
      hash.transform_keys(&:to_sym)
    rescue
      {}
    end
  end
end
