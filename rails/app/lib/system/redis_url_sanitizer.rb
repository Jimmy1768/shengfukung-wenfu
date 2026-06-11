# frozen_string_literal: true

require "uri"

module System
  class RedisUrlSanitizer
    def self.call(url)
      uri = URI.parse(url.to_s)
      uri.user = nil
      uri.password = nil
      uri.to_s
    rescue URI::InvalidURIError
      "[invalid redis url]"
    end
  end
end
