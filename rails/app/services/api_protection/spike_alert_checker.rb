# frozen_string_literal: true

module ApiProtection
  class SpikeAlertChecker
    DEFAULT_WINDOW_MINUTES = 15
    DEFAULT_MIN_EVENTS = 40
    DEFAULT_MIN_UNIQUE_SCOPES = 10

    Result = Struct.new(
      :triggered,
      :window_minutes,
      :event_count,
      :unique_scope_count,
      :top_paths,
      :reason,
      keyword_init: true
    ) do
      def triggered?
        triggered
      end
    end

    def initialize(
      window_minutes: DEFAULT_WINDOW_MINUTES,
      min_events: DEFAULT_MIN_EVENTS,
      min_unique_scopes: DEFAULT_MIN_UNIQUE_SCOPES,
      alert_sender: Notifications::Alerts::AlertSender
    )
      @window_minutes = window_minutes.to_i
      @min_events = min_events.to_i
      @min_unique_scopes = min_unique_scopes.to_i
      @alert_sender = alert_sender
    end

    def call(dry_run: false)
      cutoff = @window_minutes.minutes.ago
      scope = ApiUsageLog.where("occurred_at >= ?", cutoff)
        .where("metadata ->> 'decision' IN (?)", %w[throttle blacklist_deny])

      event_count = scope.count
      scopes = scope.pluck(Arel.sql("metadata ->> 'scope_type'"), Arel.sql("metadata ->> 'scope_id'"))
      unique_scope_count = scopes.map { |scope_type, scope_id| "#{scope_type}:#{scope_id}" }.uniq.size
      top_paths = scope.group(:request_path).order(Arel.sql("count_all DESC")).limit(5).count

      triggered = event_count >= @min_events && unique_scope_count >= @min_unique_scopes
      reason = "events=#{event_count} unique_scopes=#{unique_scope_count} thresholds=#{@min_events}/#{@min_unique_scopes}"

      result = Result.new(
        triggered: triggered,
        window_minutes: @window_minutes,
        event_count: event_count,
        unique_scope_count: unique_scope_count,
        top_paths: top_paths,
        reason: reason
      )

      send_alert(result) if triggered && !dry_run
      result
    end

    private

    def send_alert(result)
      top_paths = result.top_paths.map { |path, count| "#{path}=#{count}" }.join(", ")
      body = <<~BODY
        Abuse spike detected in last #{result.window_minutes} minutes.
        #{result.reason}
        Top paths: #{top_paths.presence || "none"}
      BODY

      @alert_sender.call(
        alert_key: "api_protection.abuse_spike",
        throttle_key: "api_protection.abuse_spike.#{result.window_minutes}m",
        subject: "[ApiProtection] Abuse spike detected",
        body: body
      )
    end
  end
end
