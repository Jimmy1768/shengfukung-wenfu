# frozen_string_literal: true

module Notifications
  module Alerts
    # Decides whether a Redis connection error is worth an email.
    #
    # Sidekiq's processor threads each block in BRPOP on Redis, so any gap in
    # Redis reaches a waiting thread at once; on a fetch error each thread calls
    # handle_exception, sleeps a second and retries. A two-second restart during
    # an unattended OpenSSL upgrade therefore produced an alert from every
    # Sidekiq process, as did a nine-second read timeout, and neither was a
    # problem: Sidekiq resumes on its own when Redis returns. Observed on
    # taiwan-01-web, 2026-09-30.
    #
    # So a connection error only alerts once connection errors have persisted
    # for ALERT_AFTER_SECONDS, and then exactly once for that outage. An outage
    # ends when QUIET_PERIOD_SECONDS pass without one; the next error starts a
    # new outage, which has to earn its own alert.
    #
    # All of this lives in process memory. It cannot use Rails.cache, and
    # AlertThrottler cannot be relied on to do it, because both are Redis: the
    # throttle fails open when it cannot reach its store, which is precisely
    # when this runs. State is per process and guarded by a Mutex, because
    # Sidekiq calls the error handler from several threads at once and they
    # all see the same outage.
    class RedisOutageTracker
      ALERT_AFTER_SECONDS = 60
      QUIET_PERIOD_SECONDS = 30

      # The one email an outage is allowed. outage_id is unique per outage in
      # this process, so a throttle key built from it can suppress a duplicate
      # within an outage but never a later outage's only alert.
      Alert = Struct.new(:unreachable_for, :outage_id, keyword_init: true)

      # clock - returns seconds; monotonic by default, so an NTP step cannot
      #         shorten or lengthen an outage.
      def initialize(clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
        @clock = clock
        @mutex = Mutex.new
        @outages = 0
        clear
      end

      # Records one connection error. Returns an Alert when, and only when,
      # this call is the one that should send the outage's email; nil
      # otherwise. The caller sends outside the lock -- holding a Mutex across
      # an HTTP request would stall every other Sidekiq thread behind it.
      def record_error
        @mutex.synchronize do
          now = @clock.call

          if @last_error_at.nil? || now - @last_error_at >= QUIET_PERIOD_SECONDS
            @outage_started_at = now
            @alerted = false
            @outages += 1
          end
          @last_error_at = now

          unreachable_for = now - @outage_started_at
          next nil if @alerted || unreachable_for < ALERT_AFTER_SECONDS

          @alerted = true
          Alert.new(unreachable_for: unreachable_for, outage_id: @outages)
        end
      end

      # For tests. Production never needs to forget an outage: the quiet period
      # does that.
      def reset!
        @mutex.synchronize { clear }
      end

      private

      def clear
        @last_error_at = nil
        @outage_started_at = nil
        @alerted = false
      end

      # One per process, built when the class loads rather than lazily: a lazy
      # `@shared ||= new` can race and leave two threads holding two trackers,
      # each of which would send its own email for the same outage.
      SHARED = new
      private_constant :SHARED

      def self.shared
        SHARED
      end
    end
  end
end
