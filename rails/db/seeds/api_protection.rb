# frozen_string_literal: true

require "zlib"
require Rails.root.join("app", "lib", "app_constants", "project").to_s

module Seeds
  module ApiProtection
    extend self

    SEED_IP = "203.0.113.45"

    def seed
      puts "Seeding API protection data..." # rubocop:disable Rails/Output
      user = seed_user
      seed_usage_log(user)
      seed_request_counter
      seed_blacklist_entry
    end

    private

    def seed_user
      User.find_or_create_by!(email: "api-protection@#{AppConstants::Project.slug}.local") do |user|
        user.english_name = "API Protection Seed"
        user.encrypted_password = User.password_hash("ApiSeed!2025")
        user.metadata = seed_metadata
      end
    end

    def seed_usage_log(user)
      ApiUsageLog.create_with(
        user: user,
        access_key: "seed-key",
        client_identifier: "seed-client",
        ip_address: SEED_IP,
        request_path: "/api/v1/seed",
        http_method: "POST",
        occurred_at: Time.current,
        metadata: seed_metadata
      ).find_or_create_by!(request_path: "/api/v1/seed", http_method: "POST", ip_address: SEED_IP)
    end

    def seed_request_counter
      bucket = Time.current.utc.strftime("%Y%m%d%H")
      ApiRequestCounter.find_or_initialize_by(
        scope_type: "IpAddress",
        scope_id: scope_identifier,
        bucket: bucket
      ).tap do |counter|
        counter.count = counter.count.to_i + 1
        counter.metadata = seed_metadata
        counter.save! if counter.changed?
      end
    end

    def seed_blacklist_entry
      BlacklistEntry.find_or_initialize_by(scope_type: "IpAddress", scope_id: scope_identifier).tap do |entry|
        entry.reason = "Seeded guardrail"
        entry.active = true
        entry.expires_at = 1.hour.from_now
        entry.metadata = seed_metadata
        entry.save! if entry.changed?
      end
    end

    def scope_identifier
      Zlib.crc32(SEED_IP)
    end

    def seed_metadata
      {
        seeded_at: Time.current.iso8601,
        seeded_by: "db:seed:api_protection"
      }
    end
  end
end
