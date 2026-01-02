require "test_helper"

class BackgroundTasksRecorderTest < ActiveSupport::TestCase
  test "start! tracks running metadata and increments attempts" do
    record = BackgroundTasks::Recorder.start!(
      task_key: "seed.recorder",
      queue: "default",
      payload: { job: "seed" }
    )
    assert_equal "running", record.status
    assert_equal 1, record.attempts
    assert_equal "default", record.queue_name

    second = BackgroundTasks::Recorder.start!(
      task_key: "seed.recorder",
      queue: "default"
    )
    assert_equal 2, second.attempts
  end

  test "succeed! sets status and metadata" do
    BackgroundTasks::Recorder.start!(task_key: "seed.recorder.success")
    record = BackgroundTasks::Recorder.succeed!(
      task_key: "seed.recorder.success",
      result_metadata: { finished: true }
    )
    assert_equal "succeeded", record.status
    assert_equal true, record.metadata["finished"]
  end

  test "fail! captures error details" do
    BackgroundTasks::Recorder.start!(task_key: "seed.recorder.fail")
    error = StandardError.new("boom")
    record = BackgroundTasks::Recorder.fail!(task_key: "seed.recorder.fail", error: error, metadata: { retry: true })
    assert_equal "failed", record.status
    assert_includes record.last_error, "StandardError: boom"
    assert_equal true, record.metadata["retry"]
  end
end
