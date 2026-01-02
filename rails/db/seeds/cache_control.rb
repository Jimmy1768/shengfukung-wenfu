# frozen_string_literal: true

require Rails.root.join("app", "lib", "app_constants", "project").to_s

module Seeds
  module CacheControl
    extend self

    def seed
      puts "Seeding cache control data..." # rubocop:disable Rails/Output
      user = seed_user
      client_checkin = seed_client_checkin(user)
      seed_cache_state(user, client_checkin)
      seed_cache_metric(user, client_checkin)
      seed_repair_task
    end

    private

    def seed_user
      User.find_or_create_by!(email: "cache-control@#{AppConstants::Project.slug}.local") do |user|
        user.english_name = "Cache Control Seed"
        user.encrypted_password = User.password_hash("CacheSeed!2025")
        user.metadata = seed_metadata
      end
    end

    def seed_client_checkin(user)
      ClientCheckin.find_or_initialize_by(client_id: "seed-cache-control-client", client_type: "web-app").tap do |checkin|
        checkin.user = user
        checkin.last_ping_at = 10.minutes.ago
        checkin.cache_revision = 5
        checkin.metadata = seed_metadata
        checkin.save! if checkin.changed?
      end
    end

    def seed_cache_state(user, checkin)
      ClientCacheState.find_or_initialize_by(
        user: user,
        client_checkin: checkin,
        state_key: "home.dashboard"
      ).tap do |state|
        state.needs_refresh = false
        state.version = 42
        state.context_reference = "seed:root_home"
        state.context_data = { seeded_by: "cache_control" }
        state.metadata = seed_metadata
        state.save! if state.changed?
      end
    end

    def seed_cache_metric(user, checkin)
      ClientCacheMetric.find_or_initialize_by(user: user, metric_key: "home.dashboard").tap do |metric|
        metric.client_checkin = checkin
        metric.hits_count = 123
        metric.misses_count = 4
        metric.refresh_count = 2
        metric.bytes_sent = 1024
        metric.last_refreshed_at = 5.minutes.ago
        metric.metadata = seed_metadata
        metric.save! if metric.changed?
      end
    end

    def seed_repair_task
      CacheRepairTask.find_or_initialize_by(repair_key: "home.dashboard").tap do |task|
        task.status = "pending"
        task.scheduled_for = 2.hours.from_now
        task.context_data = { reason: "cache_control seed task" }
        task.metadata = seed_metadata
        task.save! if task.changed?
      end
    end

    def seed_metadata
      {
        seeded_at: Time.current.iso8601,
        seeded_by: "db:seed:cache_control"
      }
    end
  end
end
