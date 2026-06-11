require "test_helper"

class RedisAppStoreTest < ActiveSupport::TestCase
  class FakeRedis
    attr_reader :calls

    def initialize
      @calls = []
      @store = {}
    end

    def get(key)
      @calls << [:get, key]
      @store[key]
    end

    def set(key, value, **options)
      @calls << [:set, key, value, options]
      @store[key] = value
      "OK"
    end

    def del(key)
      @calls << [:del, key]
      @store.delete(key)
      1
    end
  end

  test "namespaces appstate keys by app codename" do
    assert_equal "initial:appstate:assistant/session", System::RedisAppStore.namespaced_key("assistant/session")
  end

  test "rejects blank appstate keys" do
    assert_raises(ArgumentError) { System::RedisAppStore.namespaced_key(" ") }
  end

  test "reads namespaced keys through appstate client" do
    redis = FakeRedis.new

    System::RedisAppStore.stub(:client, redis) do
      System::RedisAppStore.set("rate-limit/user-1", "1", ttl: 30)
      assert_equal "1", System::RedisAppStore.get("rate-limit/user-1")
    end

    assert_equal [:set, "initial:appstate:rate-limit/user-1", "1", { ex: 30 }], redis.calls.first
    assert_equal [:get, "initial:appstate:rate-limit/user-1"], redis.calls.second
  end

  test "deletes namespaced keys through appstate client" do
    redis = FakeRedis.new

    System::RedisAppStore.stub(:client, redis) { assert_equal 1, System::RedisAppStore.delete("lock/import") }

    assert_equal [[:del, "initial:appstate:lock/import"]], redis.calls
  end
end
