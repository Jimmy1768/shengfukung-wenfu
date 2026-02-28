# frozen_string_literal: true

require "test_helper"

module Payments
  class WebhookIngestServiceTest < ActiveSupport::TestCase
    FakeTemple = Struct.new(:id)
    FakeEventLog = Struct.new(:id)

    class FakeResolver
      def initialize(adapter)
        @adapter = adapter
      end

      def resolve(provider:)
        @adapter
      end
    end

    class FakeAdapter
      def initialize(payload)
        @payload = payload
      end

      def ingest_webhook(payload:, headers:)
        @payload
      end
    end

    class FakePaymentRepository
      attr_reader :updated_metadata

      def find_by_provider_reference(**)
        nil
      end

      def update_status!(**kwargs)
        @updated_metadata = kwargs
      end
    end

    class FakeEventLogRepository
      attr_reader :failed_error, :processed_called

      def record_once!(**)
        FakeEventLog.new(1)
      end

      def mark_processed!(event_log)
        @processed_called = true
      end

      def mark_failed!(event_log, error)
        @failed_error = error
      end
    end

    test "raises when signature is invalid and marks event log failed" do
      adapter = FakeAdapter.new(
        event_type: "payment.updated",
        provider_event_id: "evt_1",
        provider_reference: "pay_1",
        status: "pending",
        signature_valid: false,
        signature_reason: "missing_signature_header",
        raw: { payload: { token: "secret" }, headers: {} }
      )
      event_repo = FakeEventLogRepository.new
      service = WebhookIngestService.new(
        provider_resolver: FakeResolver.new(adapter),
        payment_repository: FakePaymentRepository.new,
        event_log_repository: event_repo
      )

      error = assert_raises(WebhookIngestService::InvalidWebhookSignature) do
        service.call(temple: FakeTemple.new(1), provider: "stripe", payload: {}, headers: {})
      end

      assert_includes error.message, "Invalid stripe webhook signature"
      assert_instance_of WebhookIngestService::InvalidWebhookSignature, event_repo.failed_error
      assert_nil event_repo.processed_called
    end

    test "marks duplicate event as duplicate result" do
      adapter = FakeAdapter.new(
        event_type: "payment.updated",
        provider_event_id: "evt_1",
        provider_reference: "pay_1",
        status: "pending",
        signature_valid: true,
        raw: { payload: {}, headers: {} }
      )
      event_repo = Class.new do
        def record_once!(**)
          raise Payments::Repositories::PaymentEventLogRepository::DuplicateEvent, "dup"
        end

        def mark_failed!(*)
          raise "should not be called"
        end
      end.new

      service = WebhookIngestService.new(
        provider_resolver: FakeResolver.new(adapter),
        payment_repository: FakePaymentRepository.new,
        event_log_repository: event_repo
      )

      result = service.call(temple: FakeTemple.new(1), provider: "stripe", payload: {}, headers: {})
      assert result.duplicate
      assert_nil result.event_log
    end
  end
end
