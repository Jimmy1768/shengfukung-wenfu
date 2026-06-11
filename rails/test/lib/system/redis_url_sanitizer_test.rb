require "test_helper"
require Rails.root.join("app", "lib", "system", "redis_url_sanitizer").to_s

class RedisUrlSanitizerTest < ActiveSupport::TestCase
  test "removes credentials from redis urls" do
    sanitized = System::RedisUrlSanitizer.call("redis://user:secret@redis.internal:6379/2")

    assert_equal "redis://redis.internal:6379/2", sanitized
  end

  test "preserves urls without credentials" do
    sanitized = System::RedisUrlSanitizer.call("redis://redis.internal:6379/1")

    assert_equal "redis://redis.internal:6379/1", sanitized
  end

  test "returns safe label for invalid urls" do
    assert_equal "[invalid redis url]", System::RedisUrlSanitizer.call("redis://[bad")
  end
end
