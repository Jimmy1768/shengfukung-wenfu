require "test_helper"

class DataExportJobTest < ActiveSupport::TestCase
  test "requires export key" do
    job = DataExportJob.new(status: "pending")
    assert_not job.valid?
    assert_includes job.errors[:export_key], "can't be blank"
  end

  test "restricts to known statuses" do
    job = DataExportJob.new(export_key: "seed.job", status: "unknown")
    assert_not job.valid?
    assert_includes job.errors[:status], "is not included in the list"
  end
end
