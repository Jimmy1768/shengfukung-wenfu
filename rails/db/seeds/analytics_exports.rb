# frozen_string_literal: true

module Seeds
  module AnalyticsExports
    extend self

    def seed
      puts "Seeding analytics export data..." # rubocop:disable Rails/Output
      job = DataExportJob.find_or_initialize_by(export_key: "seed:user-activity-export").tap do |record|
        record.status = "pending"
        record.scheduled_at = 10.minutes.from_now
        record.range_start = 1.day.ago
        record.range_end = Time.current
        record.destination = "s3"
        record.filters = { region: "us" }
        record.metadata = seed_metadata
        record.save! if record.changed?
      end

      DataExportPayload.find_or_initialize_by(
        data_export_job: job,
        storage_location: "s3://golden-template/exports/user-activity-001.csv"
      ).tap do |payload|
        payload.checksum = "seed-checksum-001"
        payload.bytes = 1024
        payload.record_count = 12
        payload.available_at = 1.minute.from_now
        payload.metadata = seed_metadata
        payload.save! if payload.changed?
      end
    end

    private

    def seed_metadata
      {
        seeded_at: Time.current.iso8601,
        seeded_by: "db:seed:analytics_exports"
      }
    end
  end
end
