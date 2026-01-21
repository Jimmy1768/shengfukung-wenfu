# frozen_string_literal: true

# app/services/cache_payloads/invalidator.rb
#
# Marks cache states as stale when underlying data changes.
module CachePayloads
  class Invalidator
    def self.call(state_keys:, scope: ClientCacheState.all, enqueue: false)
      new(state_keys: state_keys, scope: scope, enqueue: enqueue).call
    end

    def initialize(state_keys:, scope:, enqueue:)
      @state_keys = Array(state_keys).map(&:to_s)
      @scope = scope
      @enqueue = enqueue
    end

    def call
      updated = scope.where(state_key: state_keys).update_all(
        needs_refresh: true,
        updated_at: Time.current
      )
      enqueue_refresh(scope.where(state_key: state_keys)) if enqueue
      updated
    end

    private

    attr_reader :state_keys, :scope, :enqueue

    def enqueue_refresh(relation)
      relation.find_each do |state|
        Cache::CacheRefreshWorker.perform_async(state.id)
      end
    end
  end
end
