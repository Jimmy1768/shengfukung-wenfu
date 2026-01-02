# frozen_string_literal: true

# app/jobs/daily_job.rb
# High-level scheduler that fans out daily work into targeted workers.
class DailyJob
  include Sidekiq::Job
  sidekiq_options queue: Profile::Infrastructure::JobQueues::DAILY

  def perform
    Rails.logger.info "🗓️ Running DailyJob..."

    schedule_system_tasks
    schedule_free_feature_notifications

    Rails.logger.info "✅ DailyJob completed"
  end

  private

  def schedule_system_tasks
    base_utc = Scheduling::RunTime.next_local_time("UTC", "03:00")
    base_utc += 1.day if base_utc <= Time.now.utc

    run_at_utc = Scheduling::RunTime.apply_jitter_utc(
      base_utc,
      jitter_minutes: 15,
      salt: "daily:system_tasks"
    )

    SystemTasks::DailyTasks.perform_at(run_at_utc)
    Rails.logger.info "🧰 Scheduled SystemTasks::DailyTasks at #{run_at_utc}"
  rescue => e
    Rails.logger.error "⚠️ Error scheduling SystemTasks::DailyTasks: #{e.message}"
  end

  def schedule_free_feature_notifications
    # Placeholder for future feature-specific dispatch logic.
    # Example: iterate over academies/timezones and queue timezone-aware
    # jobs via Scheduling::RunTime helpers to avoid peak hours.
  end
end
