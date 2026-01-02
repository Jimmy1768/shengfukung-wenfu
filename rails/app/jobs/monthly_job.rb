# frozen_string_literal: true

# app/jobs/monthly_job.rb
# Entrypoint for monthly cadence work.
class MonthlyJob
  include Sidekiq::Job
  sidekiq_options queue: Profile::Infrastructure::JobQueues::MONTHLY

  def perform
    Rails.logger.info "🗓️ Running MonthlyJob..."

    queue_monthly_maintenance

    Rails.logger.info "✅ MonthlyJob completed"
  end

  private

  def queue_monthly_maintenance
    Notifications::LogPruner.call
    Rails.logger.info "🛠️ Cleaned up notification logs"
  rescue => e
    Rails.logger.error "⚠️ Error queueing monthly maintenance: #{e.message}"
  end
end
