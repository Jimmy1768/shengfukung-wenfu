require "test_helper"

class DataExportJobTest < ActiveSupport::TestCase
  test "requires export key" do
    I18n.with_locale(:en) do
      job = DataExportJob.new(status: "pending")
      assert_not job.valid?
      assert_includes job.errors[:export_key], "can't be blank"
    end
  end

  test "restricts to known statuses" do
    I18n.with_locale(:en) do
      job = DataExportJob.new(export_key: "seed.job", status: "unknown")
      assert_not job.valid?
      assert_includes job.errors[:status], "is not included in the list"
    end
  end
end
