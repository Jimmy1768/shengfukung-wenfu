# frozen_string_literal: true

module BackgroundTasks
  # Helper for workers/services to track lifecycle of background tasks.
  class Recorder
    class << self
      def start!(task_key:, queue: nil, payload: {}, metadata: {})
        record = find_or_initialize(task_key)
        record.assign_attributes(
          status: "running",
          queue_name: queue,
          attempts: record.attempts.to_i + 1,
          started_at: Time.current,
          finished_at: nil,
          payload: payload,
          metadata: (record.metadata || {}).merge(metadata || {})
        )
        record.save!
        record
      end

      def succeed!(task_key:, result_metadata: {})
        update_status(task_key, status: "succeeded", finished_at: Time.current, metadata: result_metadata)
      end

      def fail!(task_key:, error:, metadata: {})
        update_status(
          task_key,
          status: "failed",
          finished_at: Time.current,
          last_error: "#{error.class}: #{error.message}",
          metadata: metadata
        )
      end

      private

      def find_or_initialize(task_key)
        BackgroundTask.find_or_initialize_by(task_key: task_key)
      end

      def update_status(task_key, status:, finished_at:, metadata:, last_error: nil)
        record = find_or_initialize(task_key)
        record.assign_attributes(
          status: status,
          finished_at: finished_at,
          last_error: last_error,
          metadata: (record.metadata || {}).merge(metadata || {})
        )
        record.save!
        record
      end
    end
  end
end
