# frozen_string_literal: true

require 'cgi'
require 'socket'

module Notifications
  module Alerts
    class SidekiqFailureHandler
      # Sidekiq::Config#handle_exception (sidekiq/config.rb) detects a
      # 2-arg handler and logs a DEPRECATION warning on every single
      # invocation. The 3-arg form is the supported shape going forward.
      # _sidekiq_config (Sidekiq's own Config object) isn't used here: its
      # most useful field -- which queues a process serves -- only matters
      # once several differently-scoped Sidekiq processes exist, which
      # isn't the case today (one production unit, one staging unit).
      def self.call(exception, context, _sidekiq_config = nil)
        return unless exception

        job = extract_job(context)
        timestamp = Time.current.utc.iso8601
        environment_label = "#{Rails.env} (#{Socket.gethostname})"

        if job
          log_and_alert_job_failure(exception:, job:, timestamp:, environment_label:)
        elsif redis_connection_error?(exception)
          log_and_track_redis_outage(exception:, context:, timestamp:, environment_label:)
        else
          log_and_alert_infra_error(exception:, context:, timestamp:, environment_label:)
        end
      rescue => e
        Rails.logger.error "[Notifications::Alerts::SidekiqFailureHandler] error: #{e.class}: #{e.message}"
      end

      # A real job failure calls handle_exception with
      # {context: "Job raised exception", job: job_hash} (or similar) --
      # the job's real class/args/jid/queue/retry_count live nested one
      # level down, at context[:job]. An internal error with no job in
      # flight (e.g. a Redis-unreachable fetch-loop failure) calls
      # handle_exception(ex) with no context argument at all, defaulting
      # to {}: there is truthfully no job there. The previous version of
      # this handler read job_class/args off the top-level context hash,
      # a key that is never present in either case, so it always reported
      # 'unknown'/nil -- for every Sidekiq failure, not only Redis
      # outages.
      def self.extract_job(context)
        return nil unless context

        context[:job] || context['job']
      end

      # context is a literal Ruby hash written at Sidekiq's own call
      # sites ({context: "...", job: job_hash}), so it is symbol-keyed in
      # practice -- but job_hash is Sidekiq's job payload deserialized
      # from JSON, so it is string-keyed. Each accessor below tolerates
      # both anyway: cheap insurance against a future Sidekiq version
      # changing either convention, not evidence that either currently
      # varies.
      def self.job_field(job, key)
        job[key.to_s] || job[key.to_sym]
      end

      def self.context_description(context)
        return nil unless context

        context[:context] || context['context']
      end

      def self.log_and_alert_job_failure(exception:, job:, timestamp:, environment_label:)
        job_class = job_field(job, :class) || 'unknown'
        arguments = job_field(job, :args)
        jid = job_field(job, :jid)
        queue = job_field(job, :queue)
        retry_count = job_field(job, :retry_count)

        Notifications::Logging::EventLogger.log(
          event: 'notifications.sidekiq.failure',
          details: {
            kind: 'job_failure',
            job_class: job_class,
            jid: jid,
            queue: queue,
            retry_count: retry_count,
            exception: exception.class.to_s,
            message: exception.message,
            args: arguments.inspect,
            environment: environment_label,
            timestamp: timestamp
          }
        )

        detail_rows = [
          jid ? "<p>Job ID: #{CGI.escapeHTML(jid.to_s)}</p>" : nil,
          queue ? "<p>Queue: #{CGI.escapeHTML(queue.to_s)}</p>" : nil,
          retry_count ? "<p>Retry count: #{CGI.escapeHTML(retry_count.to_s)}</p>" : nil
        ].compact.join

        AlertSender.call(
          # job_class alone would repeat the original bug's shape at a
          # smaller radius: two different exceptions in the same job
          # class would still share one 5-minute throttle window, so a
          # new failure mode could hide behind an already-alerted one.
          alert_key: "sidekiq_failure:job:#{job_class}:#{exception.class}",
          subject: "[Alert] Sidekiq job failed: #{job_class}",
          body: <<~HTML
            <p>Sidekiq job <strong>#{CGI.escapeHTML(job_class.to_s)}</strong> failed at #{CGI.escapeHTML(timestamp)} (#{CGI.escapeHTML(environment_label)}).</p>
            <p>Exception: #{CGI.escapeHTML(exception.class.to_s)} – #{CGI.escapeHTML(exception.message)}</p>
            <p>Arguments: #{CGI.escapeHTML(arguments.inspect)}</p>
            #{detail_rows}
          HTML
        )
      end

      # A Redis connection error with no job in flight is a fetch-loop failure:
      # a thread blocked in BRPOP found Redis gone. It is expected during any
      # restart and resolves itself, so it is counted rather than mailed -- see
      # RedisOutageTracker. Every subclass qualifies: CannotConnectError and
      # ReadTimeoutError, the two seen on 2026-09-30, both descend from
      # RedisClient::ConnectionError.
      def self.redis_connection_error?(exception)
        defined?(RedisClient::ConnectionError) && exception.is_a?(RedisClient::ConnectionError)
      end

      # The log line is written for every error on every path, unchanged. Only
      # the decision to email differs.
      def self.log_infra_error(exception:, description:, timestamp:, environment_label:)
        Notifications::Logging::EventLogger.log(
          event: 'notifications.sidekiq.failure',
          details: {
            kind: 'infra_error',
            description: description,
            exception: exception.class.to_s,
            message: exception.message,
            environment: environment_label,
            timestamp: timestamp
          }
        )
      end

      def self.infra_description(context)
        # context[:context] is Sidekiq's own human-readable description
        # for this failure site (e.g. "Invalid JSON for job", "Exception
        # during Sidekiq lifecycle event"). It's absent for the bare
        # fetch-loop case (handle_exception(ex), no context at all) --
        # the exact shape of the incident that prompted this fix.
        context_description(context) || 'no job was being processed'
      end

      def self.log_and_track_redis_outage(exception:, context:, timestamp:, environment_label:)
        log_infra_error(exception:, description: infra_description(context), timestamp:, environment_label:)

        alert = RedisOutageTracker.shared.record_error
        return unless alert

        seconds = alert.unreachable_for.round
        AlertSender.call(
          alert_key: "sidekiq_failure:redis_outage",
          # Unique per outage. AlertThrottler keys live in Redis and fail open
          # while it is down, so they cannot be what limits this to one email --
          # the tracker is. This key only stops the throttle, once Redis is back,
          # from suppressing a later outage's single alert behind an earlier one.
          throttle_key: "sidekiq_failure:redis_outage:#{Process.pid}:#{alert.outage_id}",
          subject: '[Alert] Sidekiq cannot reach Redis',
          body: <<~HTML
            <p>Sidekiq has been unable to reach Redis for at least #{seconds} seconds, as of #{CGI.escapeHTML(timestamp)} (#{CGI.escapeHTML(environment_label)}).</p>
            <p>No job was in flight -- nothing was dequeued or lost. Sidekiq resumes on its own when Redis returns; no restart is needed for that.</p>
            <p>A restart of Redis that lasts a few seconds does not send this. It is sent once per outage, after #{RedisOutageTracker::ALERT_AFTER_SECONDS} seconds without a connection.</p>
            <p>Last error: #{CGI.escapeHTML(exception.class.to_s)} – #{CGI.escapeHTML(exception.message)}</p>
          HTML
        )
      end

      def self.log_and_alert_infra_error(exception:, context:, timestamp:, environment_label:)
        description = infra_description(context)
        log_infra_error(exception:, description:, timestamp:, environment_label:)

        AlertSender.call(
          # Keyed on exception class, not collapsed to one shared bucket:
          # a Redis blip and a sustained Redis outage should throttle
          # together (that's the suppression we want), but an unrelated
          # infra failure -- a different exception class entirely --
          # should not be hidden behind it.
          alert_key: "sidekiq_failure:infra:#{exception.class}",
          subject: '[Alert] Sidekiq internal error (no job)',
          body: <<~HTML
            <p>Sidekiq hit an internal error at #{CGI.escapeHTML(timestamp)} (#{CGI.escapeHTML(environment_label)}): #{CGI.escapeHTML(description)}.</p>
            <p>No job was in flight -- nothing was dequeued or lost.</p>
            <p>Exception: #{CGI.escapeHTML(exception.class.to_s)} – #{CGI.escapeHTML(exception.message)}</p>
          HTML
        )
      end

      private_class_method :extract_job, :job_field, :context_description,
        :log_and_alert_job_failure, :log_and_alert_infra_error,
        :redis_connection_error?, :log_infra_error, :infra_description,
        :log_and_track_redis_outage
    end
  end
end
