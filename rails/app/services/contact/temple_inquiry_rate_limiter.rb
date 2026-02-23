# frozen_string_literal: true

module Contact
  class TempleInquiryRateLimiter
    USER_LIMIT_PER_HOUR = 3
    IP_LIMIT_PER_HOUR = 10

    Result = Struct.new(:allowed?, :reason, keyword_init: true)

    def self.call(user_id:, ip:)
      new(user_id:, ip:).call
    end

    def initialize(user_id:, ip:)
      @user_id = user_id
      @ip = ip.to_s.presence || "unknown"
      @window_key = Time.current.beginning_of_hour.to_i
    end

    def call
      user_count = increment(key_for("user", @user_id))
      return Result.new(allowed?: false, reason: :user_limit) if user_count > USER_LIMIT_PER_HOUR

      ip_count = increment(key_for("ip", @ip))
      return Result.new(allowed?: false, reason: :ip_limit) if ip_count > IP_LIMIT_PER_HOUR

      Result.new(allowed?: true)
    end

    private

    def key_for(scope, id)
      "contact_temple_requests:#{scope}:#{id}:#{@window_key}"
    end

    def increment(key)
      current = Rails.cache.read(key).to_i
      next_value = current + 1
      Rails.cache.write(key, next_value, expires_in: 1.hour)
      next_value
    end
  end
end
