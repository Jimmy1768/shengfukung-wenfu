# frozen_string_literal: true
require "zlib"

namespace :api_protection do
  module Helpers
    module_function

    def boolean_env(name, default: false)
      return default unless ENV.key?(name)

      ActiveModel::Type::Boolean.new.cast(ENV[name])
    end

    def require_apply!
      apply = boolean_env("APPLY", default: false)
      abort "This action is destructive. Re-run with APPLY=true to execute." unless apply
    end

    def scope_id_for_ip(ip)
      Zlib.crc32(ip.to_s)
    end

    def active_blacklist_scope
      BlacklistEntry.where(active: true).where("expires_at IS NULL OR expires_at > ?", Time.current)
    end
  end

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

  desc "Ops report: top counters, recent decisions, active blacklist entries"
  task report: :environment do
    window_minutes = ENV.fetch("WINDOW_MINUTES", "60").to_i
    limit = ENV.fetch("LIMIT", "25").to_i
    cutoff = window_minutes.minutes.ago

    puts "ApiProtection report window=#{window_minutes}m limit=#{limit}"
    puts ""

    puts "Top counters:"
    counters = ApiRequestCounter.where("updated_at >= ?", cutoff).order(count: :desc).limit(limit)
    counters.each do |counter|
      puts "  scope=#{counter.scope_type}:#{counter.scope_id} bucket=#{counter.bucket} count=#{counter.count} meta=#{counter.metadata}"
    end
    puts "  (none)" if counters.empty?

    puts ""
    puts "Recent blocked/throttled decisions:"
    logs = ApiUsageLog.where("occurred_at >= ?", cutoff)
      .where("metadata ->> 'decision' IN (?)", %w[throttle blacklist_deny])
      .order(occurred_at: :desc)
      .limit(limit)
    logs.each do |log|
      decision = log.metadata.to_h["decision"]
      scope_type = log.metadata.to_h["scope_type"]
      scope_id = log.metadata.to_h["scope_id"]
      puts "  at=#{log.occurred_at.iso8601} decision=#{decision} path=#{log.request_path} method=#{log.http_method} ip=#{log.ip_address} scope=#{scope_type}:#{scope_id}"
    end
    puts "  (none)" if logs.empty?

    puts ""
    puts "Active blacklist entries:"
    entries = Helpers.active_blacklist_scope.order(created_at: :desc).limit(limit)
    entries.each do |entry|
      puts "  id=#{entry.id} scope=#{entry.scope_type}:#{entry.scope_id} reason=#{entry.reason} expires_at=#{entry.expires_at || 'none'}"
    end
    puts "  (none)" if entries.empty?
  end

  desc "Safely unblock an IP (set active=false on matching blacklist entries). Usage: IP=1.2.3.4 APPLY=true"
  task unblock_ip: :environment do
    ip = ENV["IP"].to_s.strip
    abort "IP is required (e.g., IP=203.0.113.5)" if ip.blank?

    scope_id = Helpers.scope_id_for_ip(ip)
    scope = BlacklistEntry.where(scope_type: "IpAddress", scope_id: scope_id, active: true)

    puts "Found #{scope.count} active entries for IP=#{ip} scope_id=#{scope_id}"
    if scope.none?
      puts "Nothing to unblock."
      next
    end

    Helpers.require_apply!
    now = Time.current
    updated = scope.find_each.sum do |entry|
      metadata = entry.metadata.to_h.merge("unblocked_at" => now.iso8601, "unblock_action" => "api_protection:unblock_ip")
      entry.update_columns(active: false, metadata: metadata, updated_at: now)
      1
    end
    puts "Deactivated #{updated} entries."
  end

  desc "Safely unblock by explicit scope. Usage: SCOPE_TYPE=User SCOPE_ID=123 APPLY=true"
  task unblock_scope: :environment do
    scope_type = ENV["SCOPE_TYPE"].to_s.strip
    scope_id = ENV["SCOPE_ID"].to_s.strip
    abort "SCOPE_TYPE is required" if scope_type.blank?
    abort "SCOPE_ID is required" if scope_id.blank?

    scope = BlacklistEntry.where(scope_type: scope_type, scope_id: scope_id, active: true)
    puts "Found #{scope.count} active entries for scope=#{scope_type}:#{scope_id}"
    if scope.none?
      puts "Nothing to unblock."
      next
    end

    Helpers.require_apply!
    now = Time.current
    updated = scope.find_each.sum do |entry|
      metadata = entry.metadata.to_h.merge("unblocked_at" => now.iso8601, "unblock_action" => "api_protection:unblock_scope")
      entry.update_columns(active: false, metadata: metadata, updated_at: now)
      1
    end
    puts "Deactivated #{updated} entries."
  end

  desc "Safely reset stale counters for scope/class. Usage: SCOPE_TYPE=User SCOPE_ID=1 ENDPOINT_CLASS=api.account.write APPLY=true"
  task reset_counters: :environment do
    scope_type = ENV["SCOPE_TYPE"].to_s.strip
    scope_id = ENV["SCOPE_ID"].to_s.strip
    endpoint_class = ENV["ENDPOINT_CLASS"].to_s.strip
    cutoff_minutes = ENV.fetch("OLDER_THAN_MINUTES", "0").to_i

    relation = ApiRequestCounter.all
    relation = relation.where(scope_type: scope_type) if scope_type.present?
    relation = relation.where(scope_id: scope_id) if scope_id.present?
    relation = relation.where("bucket LIKE ?", "%:#{endpoint_class}:%") if endpoint_class.present?
    relation = relation.where("updated_at < ?", cutoff_minutes.minutes.ago) if cutoff_minutes.positive?

    puts "Matching counters: #{relation.count}"
    abort "No filter supplied; provide at least one of SCOPE_TYPE, SCOPE_ID, ENDPOINT_CLASS, OLDER_THAN_MINUTES." if scope_type.blank? && scope_id.blank? && endpoint_class.blank? && cutoff_minutes <= 0
    if relation.none?
      puts "Nothing to reset."
      next
    end

    Helpers.require_apply!
    deleted = relation.delete_all
    puts "Deleted #{deleted} counters."
  end

  desc "Check repeated abuse spikes and send ops alert when thresholds are crossed"
  task alert_spikes: :environment do
    window_minutes = ENV.fetch("WINDOW_MINUTES", ApiProtection::SpikeAlertChecker::DEFAULT_WINDOW_MINUTES.to_s).to_i
    min_events = ENV.fetch("MIN_EVENTS", ApiProtection::SpikeAlertChecker::DEFAULT_MIN_EVENTS.to_s).to_i
    min_unique_scopes = ENV.fetch("MIN_UNIQUE_SCOPES", ApiProtection::SpikeAlertChecker::DEFAULT_MIN_UNIQUE_SCOPES.to_s).to_i
    dry_run = Helpers.boolean_env("DRY_RUN", default: false)

    checker = ApiProtection::SpikeAlertChecker.new(
      window_minutes: window_minutes,
      min_events: min_events,
      min_unique_scopes: min_unique_scopes
    )
    result = checker.call(dry_run: dry_run)

    puts "Spike check window=#{window_minutes}m events=#{result.event_count} unique_scopes=#{result.unique_scope_count} triggered=#{result.triggered?} dry_run=#{dry_run}"
    puts "Reason: #{result.reason}"
    puts "Top paths: #{result.top_paths}"
  end
end
