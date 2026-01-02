require "test_helper"

class DataExportPayloadTest < ActiveSupport::TestCase
  test "requires storage location and available at timestamp" do
    job = DataExportJob.create!(
      export_key: "seed.payload",
      status: "pending"
    )
    payload = DataExportPayload.new(data_export_job: job)
    assert_not payload.valid?
    assert_includes payload.errors[:storage_location], "can't be blank"
    assert_includes payload.errors[:available_at], "can't be blank"
  end
end
