# frozen_string_literal: true

require "test_helper"

module Notifications
  module Alerts
    # A Redis blip no longer emails; only a sustained outage does.
    #
    # Observed on taiwan-01-web, 2026-09-30: an unattended OpenSSL upgrade
    # restarted redis-server for about two seconds, and later a read timeout
    # lasted nine. Every Sidekiq process emailed for both and both resolved
    # themselves. These drive the handler with a clock the test controls, so
    # a minute of outage takes no time to run.
    class RedisOutageAlertTest < ActiveSupport::TestCase
      class FakeClock
        attr_reader :now

        def initialize(now = 10_000.0) = @now = now
        def call = @now
        def advance(seconds) = @now += seconds
      end

      setup do
        @clock = FakeClock.new
        @tracker = RedisOutageTracker.new(clock: @clock)
      end

      def connection_error(klass = RedisClient::CannotConnectError)
        klass.new("Connection refused - connect(2) for 127.0.0.1:6379")
      end

      # Sidekiq retries a failed fetch after a one-second sleep, so an outage
      # reaches the handler about once a second per processor thread.
      def outage_lasting(seconds, klass: RedisClient::CannotConnectError)
        emails = []
        RedisOutageTracker.stub(:shared, @tracker) do
          AlertSender.stub(:call, ->(**kwargs) { emails << kwargs; true }) do
            (0..seconds).each do |second|
              SidekiqFailureHandler.call(connection_error(klass), {}, nil)
              @clock.advance(1) unless second == seconds
            end
          end
        end
        emails
      end

      # --- criterion 6: the 2026-09-30 cases ------------------------------

      test "a two-second restart, as during the OpenSSL upgrade, sends nothing" do
        assert_empty outage_lasting(2),
          "a two-second Redis restart sent an alert. Sidekiq resumes on its own after one; " \
          "this is the unattended-upgrade case that paged on 2026-09-30."
      end

      test "a nine-second read timeout sends nothing" do
        assert_empty outage_lasting(9, klass: RedisClient::ReadTimeoutError),
          "a nine-second outage sent an alert; only one lasting 60 seconds may"
      end

      test "an outage lasting 61 seconds sends exactly one email" do
        emails = outage_lasting(61)

        assert_equal 1, emails.length,
          "a 61-second outage sent #{emails.length} emails. It must send exactly one, " \
          "and only once the outage has lasted #{RedisOutageTracker::ALERT_AFTER_SECONDS} seconds."
      end

      # --- criterion 1: nothing before sixty seconds ----------------------

      test "fifty-nine seconds of errors send nothing" do
        assert_empty outage_lasting(59)
      end

      test "the email is sent on the first error at sixty seconds, not before" do
        emails = []
        RedisOutageTracker.stub(:shared, @tracker) do
          AlertSender.stub(:call, ->(**kwargs) { emails << kwargs; true }) do
            # Intervals exact in binary: 59.9 + 0.1 does not sum to 60.0 in a
            # float, and a boundary test that misses its boundary proves nothing.
            SidekiqFailureHandler.call(connection_error, {}, nil)
            [25, 25, 9.5].each do |gap|
              @clock.advance(gap)
              SidekiqFailureHandler.call(connection_error, {}, nil)
            end
            assert_empty emails, "sent at 59.5 seconds"

            @clock.advance(0.5)
            SidekiqFailureHandler.call(connection_error, {}, nil)
          end
        end

        assert_equal 1, emails.length
      end

      test "every subclass of RedisClient::ConnectionError is held back" do
        [RedisClient::CannotConnectError, RedisClient::ReadTimeoutError,
         RedisClient::TimeoutError, RedisClient::ConnectionError].each do |klass|
          @tracker.reset!
          assert_empty outage_lasting(9, klass: klass), "#{klass} was not held back"
        end
      end

      # --- criterion 2: what the one email says, and that it is one --------

      test "the outage email says how long Redis has been unreachable and that Sidekiq recovers" do
        email = outage_lasting(61).first

        assert_equal "[Alert] Sidekiq cannot reach Redis", email[:subject]
        assert_match(/at least 60 seconds/, email[:body])
        assert_includes email[:body], "resumes on its own when Redis returns"
      end

      test "further errors in the same outage send nothing more" do
        emails = outage_lasting(61)
        RedisOutageTracker.stub(:shared, @tracker) do
          AlertSender.stub(:call, ->(**kwargs) { emails << kwargs; true }) do
            300.times do
              @clock.advance(1)
              SidekiqFailureHandler.call(connection_error, {}, nil)
            end
          end
        end

        assert_equal 1, emails.length,
          "a six-minute outage sent #{emails.length} emails; the second and later were the " \
          "once-per-outage guard failing"
      end

      # --- criterion 3: an outage ends after thirty quiet seconds ----------

      test "thirty quiet seconds end an outage, and the next must last sixty on its own" do
        assert_equal 1, outage_lasting(61).length

        @clock.advance(30)
        emails = outage_lasting(59)
        assert_empty emails, "a new outage alerted before it had lasted 60 seconds itself"

        @clock.advance(30)
        assert_equal 1, outage_lasting(61).length, "a second full outage must earn its own alert"
      end

      test "a gap shorter than thirty seconds is the same outage" do
        emails = []
        RedisOutageTracker.stub(:shared, @tracker) do
          AlertSender.stub(:call, ->(**kwargs) { emails << kwargs; true }) do
            SidekiqFailureHandler.call(connection_error, {}, nil)
            [29, 29, 7].each do |gap|
              @clock.advance(gap)
              SidekiqFailureHandler.call(connection_error, {}, nil)
            end
          end
        end

        assert_equal 1, emails.length,
          "errors 29, 29 and 7 seconds apart are one 65-second outage and must alert once"
      end

      test "each outage gets its own throttle key, so an earlier one cannot suppress it" do
        first = outage_lasting(61).first
        @clock.advance(31)
        second = outage_lasting(61).first

        refute_equal first[:throttle_key], second[:throttle_key],
          "AlertThrottler keys are in Redis; sharing one across outages would let the " \
          "first outage's key swallow the second outage's only email once Redis is back"
      end

      # --- criterion 4: per process, and one email from many threads -------

      # How the thread safety is tested, and why the first attempt was wrong.
      #
      # The first version of this case fired forty threads at one outage and
      # asserted a single email. It passed with the Mutex removed. On MRI the
      # GVL made the read of @alerted and the write of @alerted effectively
      # atomic: a sleep at the start of the critical section only staggers
      # when threads wake, and nothing releases the lock between the check and
      # the set. A single-email assertion therefore cannot tell a correct
      # tracker from an unlocked one, and would have let the lock be deleted.
      #
      # So this measures mutual exclusion directly. The clock is the first
      # thing called inside the critical section, so it counts how many threads
      # are inside at once and sleeps while it is there, which releases the GVL
      # and lets any unlocked thread in. Locked, the count never exceeds one.
      # Unlocked, most of the forty are inside together. That is the property
      # the email count depends on, and on a runtime without a GVL it is the
      # only thing standing between one outage and forty emails.
      test "forty concurrent errors in one outage go through the decision one at a time, and send one email" do
        now = 10_000.0
        inside = 0
        most_inside = 0
        counter = Mutex.new
        clock = lambda do
          counter.synchronize { inside += 1; most_inside = [most_inside, inside].max }
          sleep 0.002
          counter.synchronize { inside -= 1 }
          now
        end
        tracker = RedisOutageTracker.new(clock: clock)

        # Errors under thirty seconds apart keep it one outage, and the seeding
        # stops at fifty seconds so that no seed call spends the outage's one
        # alert: the threads are the ones that cross sixty, all together.
        tracker.record_error
        [25, 25].each { |gap| now += gap; tracker.record_error }
        now += 11
        most_inside = 0

        gate = Queue.new
        threads = Array.new(40) { Thread.new { gate.pop; tracker.record_error } }
        40.times { gate << :go }
        alerts = threads.map(&:value).compact

        assert_equal 1, most_inside,
          "#{most_inside} threads were inside the outage decision at the same moment. " \
          "It must be one: the check for an existing alert and the recording of a new one " \
          "have to happen together, or concurrent errors can each decide to send."
        assert_equal 1, alerts.length, "#{alerts.length} of 40 concurrent errors decided to alert"
      end

      # Rails.cache is replaced by a store that records any call and then
      # raises, as a Redis-backed store would during an outage. AlertSender is
      # stubbed, so this covers the tracker and the handler's decision alone --
      # which is exactly the part that has to work while Redis is down.
      test "the state is held in process memory, not in Rails.cache" do
        cache_calls = []
        unreachable = Object.new
        unreachable.define_singleton_method(:method_missing) do |name, *|
          cache_calls << name
          raise RedisClient::CannotConnectError, "Redis is down"
        end
        unreachable.define_singleton_method(:respond_to_missing?) { |*| true }

        Rails.stub(:cache, unreachable) do
          RedisOutageTracker.stub(:shared, @tracker) do
            AlertSender.stub(:call, ->(**) { true }) do
              assert_nothing_raised do
                SidekiqFailureHandler.call(connection_error, {}, nil)
                @clock.advance(61)
                SidekiqFailureHandler.call(connection_error, {}, nil)
              end
            end
          end
        end

        assert_empty cache_calls, "the outage tracker touched Rails.cache, which is Redis"
      end

      # --- criterion 5: everything else is unchanged -----------------------

      test "a job failure caused by a Redis connection error still alerts at once" do
        emails = []
        RedisOutageTracker.stub(:shared, @tracker) do
          AlertSender.stub(:call, ->(**kwargs) { emails << kwargs; true }) do
            SidekiqFailureHandler.call(connection_error, { job: { "class" => "SomeJob", "args" => [] } }, nil)
          end
        end

        assert_equal 1, emails.length, "a job was in flight, so this is a job failure, not a fetch blip"
        assert_equal "sidekiq_failure:job:SomeJob:RedisClient::CannotConnectError", emails.first[:alert_key]
      end

      test "an infra error that is not a Redis connection error still alerts at once" do
        emails = []
        RedisOutageTracker.stub(:shared, @tracker) do
          AlertSender.stub(:call, ->(**kwargs) { emails << kwargs; true }) do
            SidekiqFailureHandler.call(JSON::ParserError.new("bad"), { context: "Invalid JSON for job" }, nil)
          end
        end

        assert_equal 1, emails.length
        assert_equal "sidekiq_failure:infra:JSON::ParserError", emails.first[:alert_key]
      end

      test "every Redis connection error is still logged, including the ones that send nothing" do
        logged = []
        Notifications::Logging::EventLogger.stub(:log, ->(**kwargs) { logged << kwargs }) do
          outage_lasting(2)
        end

        assert_equal 3, logged.length, "one notifications.sidekiq.failure line per error, as before"
        assert(logged.all? { |entry| entry[:event] == "notifications.sidekiq.failure" })
        assert(logged.all? { |entry| entry.dig(:details, :exception) == "RedisClient::CannotConnectError" })
      end
    end
  end
end
