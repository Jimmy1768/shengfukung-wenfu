# frozen_string_literal: true

# app/jobs/weekly_job.rb
# Gatekeeper job that fans out weekly tasks so each worker can fail independently.
class WeeklyJob
  include Sidekiq::Job
  sidekiq_options queue: Profile::Infrastructure::JobQueues::WEEKLY

  def perform
    Rails.logger.info "📅 Running WeeklyJob..."

    queue_weekly_reports
    queue_weekly_notifications

    Rails.logger.info "✅ WeeklyJob completed"
  end

  private

  def queue_weekly_reports
    base_utc = Scheduling::RunTime.next_local_time("UTC", "06:00")
    base_utc += 1.week if base_utc <= Time.now.utc

    run_at_utc = Scheduling::RunTime.apply_jitter_utc(
      base_utc,
      jitter_minutes: 30,
      salt: "weekly:reports"
    )

    # TODO: wire up the actual worker(s) that produce weekly reporting digests.
    Rails.logger.info "📰 Weekly reports placeholder scheduled for #{run_at_utc}"
  rescue => e
    Rails.logger.error "⚠️ Error queueing weekly reports: #{e.message}"
  end

  def queue_weekly_notifications
    # Placeholder for weekly notification workers (emails, push, etc.).
  end
end
