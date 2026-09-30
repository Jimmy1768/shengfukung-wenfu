# frozen_string_literal: true

require "test_helper"

module Notifications
  module Alerts
    class SidekiqFailureHandlerTest < ActiveSupport::TestCase
      setup { RedisOutageTracker.shared.reset! }

      def call_and_capture(exception, context)
        calls = []
        AlertSender.stub(:call, ->(**kwargs) { calls << kwargs; true }) do
          SidekiqFailureHandler.call(exception, context, nil)
        end
        calls
      end

      test "a real job failure reports the real job class, args, jid, queue, and retry count" do
        exception = ArgumentError.new("bad thing happened")
        context = {
          context: "Job raised exception",
          job: {
            "class" => "PlatformBillingLifecycleJob",
            "args" => [{ "reference_time" => "2026-08-26T00:00:00Z" }],
            "jid" => "abc123def456",
            "queue" => "default",
            "retry_count" => 2
          }
        }

        calls = call_and_capture(exception, context)

        assert_equal 1, calls.length
        call = calls.first
        assert_equal "sidekiq_failure:job:PlatformBillingLifecycleJob:ArgumentError", call[:alert_key]
        assert_equal "[Alert] Sidekiq job failed: PlatformBillingLifecycleJob", call[:subject]
        assert_includes call[:body], "PlatformBillingLifecycleJob"
        assert_includes call[:body], "ArgumentError"
        assert_includes call[:body], "bad thing happened"
        assert_includes call[:body], "abc123def456"
        assert_includes call[:body], "default"
        assert_includes call[:body], "Retry count: 2"
        assert_includes call[:body], "reference_time"
      end

      # Uses an infra error that still alerts at once. It used a Redis
      # connection error until 2026-09-30, when those stopped mailing
      # immediately; the subject of this case is truthful no-job reporting,
      # which is unchanged for every other infra error.
      test "an infra-level error with no job in flight is reported truthfully, not as a phantom job named unknown" do
        exception = IOError.new("closed stream")
        context = {}

        calls = call_and_capture(exception, context)

        assert_equal 1, calls.length
        call = calls.first
        assert_equal "sidekiq_failure:infra:IOError", call[:alert_key]
        assert_equal "[Alert] Sidekiq internal error (no job)", call[:subject]
        refute_includes call[:subject], "unknown"
        refute_includes call[:body], "job <strong>unknown</strong>"
        assert_includes call[:body], "No job was in flight -- nothing was dequeued or lost."
        assert_includes call[:body], "IOError"
        assert_includes call[:body], "closed stream"
      end

      test "an infra-level error uses Sidekiq's own context description when present" do
        exception = JSON::ParserError.new("unexpected token")
        context = { context: "Invalid JSON for job" }

        calls = call_and_capture(exception, context)

        assert_equal 1, calls.length
        assert_includes calls.first[:body], "Invalid JSON for job"
      end

      test "job failure and infra error alert keys never collide even for the same exception class" do
        exception_class_name = "IOError"
        job_context = { job: { "class" => "SomeJob", "args" => [] } }
        infra_context = {}

        job_calls = call_and_capture(IOError.new("x"), job_context)
        infra_calls = call_and_capture(IOError.new("x"), infra_context)

        refute_equal job_calls.first[:alert_key], infra_calls.first[:alert_key]
        assert_includes infra_calls.first[:alert_key], exception_class_name
      end

      test "two different exceptions in the same job class get different throttle keys" do
        job_context = { job: { "class" => "SomeJob", "args" => [] } }

        first = call_and_capture(ArgumentError.new("a"), job_context)
        second = call_and_capture(TypeError.new("b"), job_context)

        refute_equal first.first[:alert_key], second.first[:alert_key]
      end

      test "the alert body identifies the environment and host, not just which inbox it landed in" do
        calls = call_and_capture(StandardError.new("x"), {})

        assert_includes calls.first[:body], Rails.env.to_s
      end

      test "tolerates a job hash with symbol keys as well as string keys" do
        exception = StandardError.new("boom")
        context = { job: { class: "SymbolKeyedJob", args: [1] } }

        calls = call_and_capture(exception, context)

        assert_includes calls.first[:subject], "SymbolKeyedJob"
      end

      test "does nothing when there is no exception" do
        calls = call_and_capture(nil, { job: { "class" => "SomeJob" } })

        assert_empty calls
      end

      test "swallows its own errors rather than raising into Sidekiq's error handler chain" do
        exception = StandardError.new("boom")

        AlertSender.stub(:call, ->(**) { raise "alerting itself failed" }) do
          assert_nothing_raised do
            SidekiqFailureHandler.call(exception, {}, nil)
          end
        end
      end
    end
  end
end
