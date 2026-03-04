# frozen_string_literal: true

# app/services/cache_payloads/fetch_service.rb
#
# Fetches (or rebuilds) a cache payload for the requested state key.
module CachePayloads
  class FetchService
    Result = Struct.new(:state_key, :version, :generated_at, :payload, :from_cache, keyword_init: true)

    def self.call(...)
      new(...).call
    end

    def initialize(state_key:, user:, client_checkin:, force_refresh: false, options: {})
      @state_key = state_key.to_s
      @user = user
      @client_checkin = client_checkin
      @force_refresh = force_refresh
      @options = options || {}
    end

    def call
      state = locate_state
      cache_key = state.context_reference.presence || build_cache_key(state)

      if can_use_cache?(state) && !force_refresh
        bundle = Cache::Storage.read(cache_key)
        if bundle.present?
          record_metric(:hit, state)
          return build_result(bundle, from_cache: true)
        end
      end

      record_metric(:miss, state)
      rebuild_payload(state, cache_key)
    end

    private

    attr_reader :state_key, :user, :client_checkin, :force_refresh, :options

    def locate_state
      ClientCacheState.find_or_initialize_by(
        user: user,
        client_checkin: client_checkin,
        state_key: state_key
      )
    end

    def builder_class
      CachePayloads::Registry.fetch(state_key)
    end

    def builder
      @builder ||= builder_class.new(
        user: user,
        client_checkin: client_checkin,
        options: options
      )
    end

    def can_use_cache?(state)
      !state.needs_refresh?
    end

    def build_cache_key(state)
      Cache::Storage.cache_key(
        state_key: state.state_key,
        user_id: state.user_id,
        client_id: state.client_checkin_id,
        slug: options[:slug]
      )
    end

    def rebuild_payload(state, cache_key)
      payload = builder.build_payload
      generated_at = Time.current
      version = state.version.to_i + 1
      bundle = {
        "state_key" => state_key,
        "version" => version,
        "generated_at" => generated_at.iso8601,
        "payload" => payload
      }

      Cache::Storage.write(cache_key, bundle, ttl: builder.ttl_seconds)

      state.update!(
        needs_refresh: false,
        version: version,
        context_reference: cache_key,
        context_data: state.context_data.merge("generated_at" => generated_at.iso8601)
      )

      record_metric(:refresh, state)
      build_result(bundle, from_cache: false)
    rescue => e
      schedule_repair(state, cache_key, e)
      raise
    end

    def build_result(bundle, from_cache:)
      generated_at = begin
        Time.zone.parse(bundle["generated_at"].to_s)
      rescue StandardError
        Time.current
      end

      Result.new(
        state_key: state_key,
        version: bundle["version"],
        generated_at: generated_at,
        payload: bundle["payload"],
        from_cache: from_cache
      )
    end

    def record_metric(type, state)
      metric = ClientCacheMetric.find_or_initialize_by(
        user: state.user,
        client_checkin: state.client_checkin,
        metric_key: state.state_key
      )

      case type
      when :hit
        metric.hits_count += 1
      when :miss
        metric.misses_count += 1
      when :refresh
        metric.refresh_count += 1
        metric.last_refreshed_at = Time.current
      end

      metric.save!
    end

    def schedule_repair(state, cache_key, error)
      CacheRepairTask.create!(
        repair_key: "cache_payload:#{state.state_key}",
        user: state.user,
        client_checkin: state.client_checkin,
        context_data: {
          cache_key: cache_key,
          state_key: state.state_key
        },
        metadata: {
          error: error.message
        }
      )
    rescue NameError
      Rails.logger.error("cache_payload failure for #{state.state_key}: #{error.message}")
    end
  end
end
