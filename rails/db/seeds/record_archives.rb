# frozen_string_literal: true

require Rails.root.join("app", "lib", "app_constants", "project").to_s

module Seeds
  module RecordArchives
    extend self

    def seed
      puts "Seeding record archive data..." # rubocop:disable Rails/Output
      user = seed_user
      seed_financial_entry(user)
      seed_audit_log(user)
      seed_usage_snapshot(user)
      seed_message_archive(user)
      seed_lifecycle_event(user)
    end

    private

    def seed_user
      User.find_or_create_by!(email: "record-archives@#{AppConstants::Project.slug}.local") do |user|
        user.english_name = "Record Archive Seed"
        user.encrypted_password = User.password_hash("RecordArchiveSeed!42")
        user.metadata = seed_metadata
      end
    end

    def seed_financial_entry(user)
      FinancialLedgerEntry.find_or_initialize_by(external_reference: "seed-financial-entry-001").tap do |entry|
        entry.user = user
        entry.entry_type = "adjustment"
        entry.currency = "USD"
        entry.amount = 1000
        entry.tax_amount = 80
        entry.status = "succeeded"
        entry.entry_date = Date.current
        entry.user_name_snapshot = user.english_name
        entry.user_email_snapshot = user.email
        entry.details = { source: "cache_control seed" }
        entry.metadata = seed_metadata
        entry.save! if entry.changed?
      end
    end

    def seed_audit_log(user)
      SystemAuditLog.find_or_initialize_by(action: "seed.record_archive").tap do |log|
        log.admin = nil
        log.user = user
        log.target_type = "CacheControl"
        log.action = "seed.record_archive"
        log.admin_name_snapshot = "system"
        log.user_name_snapshot = user.english_name
        log.occurred_at = Time.current
        log.metadata = seed_metadata
        log.save! if log.changed?
      end
    end

    def seed_usage_snapshot(user)
      UsageBillingSnapshot.find_or_initialize_by(
        user: user,
        usage_type: "api_calls",
        bucket_date: Date.current
      ).tap do |snapshot|
        snapshot.user_name_snapshot = user.english_name
        snapshot.quantity = 120
        snapshot.bytes_consumed = 204800
        snapshot.seats_active = 5
        snapshot.metadata = seed_metadata
        snapshot.save! if snapshot.changed?
      end
    end

    def seed_message_archive(user)
      MessageDeliveryArchive.find_or_initialize_by(
        channel: "email",
        recipient: user.email,
        message_key: "seed.record_archive.notification"
      ).tap do |archive|
        archive.user = user
        archive.user_name_snapshot = user.english_name
        archive.recipient_name_snapshot = user.english_name
        archive.payload = { message: "Archive seed" }
        archive.status = "delivered"
        archive.delivered_at = Time.current
        archive.metadata = seed_metadata
        archive.save! if archive.changed?
      end
    end

    def seed_lifecycle_event(user)
      AccountLifecycleEvent.find_or_initialize_by(user: user, event_type: "seed.initial_sync").tap do |event|
        event.user_name_snapshot = user.english_name
        event.details = { reason: "seeded record archives" }
        event.occurred_at = Time.current
        event.metadata = seed_metadata
        event.save! if event.changed?
      end
    end

    def seed_metadata
      {
        seeded_at: Time.current.iso8601,
        seeded_by: "db:seed:record_archives"
      }
    end
  end
end
