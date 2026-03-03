# frozen_string_literal: true

namespace :api_protection do
  desc "Prune low-signal API protection data (daily retention cleanup)"
  task cleanup: :environment do
    low_signal_hours = ENV.fetch("LOW_SIGNAL_HOURS", "48").to_i
    high_signal_days = ENV.fetch("HIGH_SIGNAL_DAYS", "60").to_i
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", "false"))

    low_signal_cutoff = low_signal_hours.hours.ago
    high_signal_cutoff = high_signal_days.days.ago

    low_signal_log_scope = ApiUsageLog.where("occurred_at < ?", low_signal_cutoff)
      .where("COALESCE(metadata ->> 'decision', 'allow') NOT IN (?)", %w[throttle blacklist_deny])
    high_signal_log_scope = ApiUsageLog.where("occurred_at < ?", high_signal_cutoff)
      .where("metadata ->> 'decision' IN (?)", %w[throttle blacklist_deny])
    old_counter_scope = ApiRequestCounter.where("updated_at < ?", low_signal_cutoff)

    low_signal_logs = low_signal_log_scope.count
    high_signal_logs = high_signal_log_scope.count
    old_counters = old_counter_scope.count

    puts "ApiProtection cleanup DRY_RUN=#{dry_run} low_signal_hours=#{low_signal_hours} high_signal_days=#{high_signal_days}"
    puts "Would delete: low_signal_logs=#{low_signal_logs}, high_signal_logs=#{high_signal_logs}, counters=#{old_counters}"

    next if dry_run

    deleted_low_signal_logs = low_signal_log_scope.delete_all
    deleted_high_signal_logs = high_signal_log_scope.delete_all
    deleted_counters = old_counter_scope.delete_all

    puts "Deleted: low_signal_logs=#{deleted_low_signal_logs}, high_signal_logs=#{deleted_high_signal_logs}, counters=#{deleted_counters}"
  end
end
