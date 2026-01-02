# frozen_string_literal: true

module AppConstants
  module Locales
    AVAILABLE = [
      {
        code: "en-US",
        name: "English (US)",
        locale_key: "en",
        timezone: "America/New_York",
        currency: "USD"
      },
      {
        code: "zh-TW",
        name: "中文（台灣）",
        locale_key: "zh-TW",
        timezone: "Asia/Taipei",
        currency: "TWD"
      },
      {
        code: "ja-JP",
        name: "日本語",
        locale_key: "ja",
        timezone: "Asia/Tokyo",
        currency: "JPY"
      }
    ].freeze

    DEFAULT_CODE = "zh-TW".freeze

    def self.find(code_or_key)
      return AVAILABLE.find { |entry| entry[:code] == DEFAULT_CODE } if code_or_key.nil?

      AVAILABLE.find do |entry|
        entry[:code] == code_or_key || entry[:locale_key] == code_or_key
      end || AVAILABLE.find { |entry| entry[:code] == DEFAULT_CODE }
    end
  end
end
