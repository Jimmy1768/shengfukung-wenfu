require "test_helper"

class ApiRequestCounterTest < ActiveSupport::TestCase
  test "requires bucket value" do
    counter = ApiRequestCounter.new(scope_type: "IpAddress")
    assert_not counter.valid?
    assert_includes counter.errors[:bucket], "can't be blank"
  end

  test "can track with a bucket" do
    counter = ApiRequestCounter.create!(
      scope_type: "IpAddress",
      bucket: Time.current.utc.strftime("%Y%m%d%H")
    )
    assert_equal 0, counter.count
  end
end
