require "test_helper"

class BackgroundTaskTest < ActiveSupport::TestCase
  test "validates presence of task_key" do
    I18n.with_locale(:en) do
      task = BackgroundTask.new(status: "pending")
      assert_not task.valid?
      assert_includes task.errors[:task_key], "can't be blank"
    end
  end

  test "enforces known statuses" do
    I18n.with_locale(:en) do
      task = BackgroundTask.new(task_key: "seed.task", status: "invalid-status")
      assert_not task.valid?
      assert_includes task.errors[:status], "is not included in the list"
    end
  end
end
