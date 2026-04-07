# frozen_string_literal: true

require "cgi"
require "digest"

module Payments
  module Taiwan
    module EcpayChecksum
      module_function

      def generate(fields:, hash_key:, hash_iv:)
        normalized = fields.to_h.stringify_keys.except("CheckMacValue").sort.to_h
        raw = "HashKey=#{hash_key}&#{normalized.to_query}&HashIV=#{hash_iv}"
        encoded = CGI.escape(raw).downcase
        encoded = normalize_encoded_string(encoded)
        Digest::SHA256.hexdigest(encoded).upcase
      end

      def valid?(fields:, hash_key:, hash_iv:)
        received = fields.to_h.stringify_keys["CheckMacValue"].to_s.upcase
        return false if received.blank?

        ActiveSupport::SecurityUtils.secure_compare(
          generate(fields:, hash_key:, hash_iv:),
          received
        )
      end

      def normalize_encoded_string(value)
        value
          .gsub("%2d", "-")
          .gsub("%5f", "_")
          .gsub("%2e", ".")
          .gsub("%21", "!")
          .gsub("%2a", "*")
          .gsub("%28", "(")
          .gsub("%29", ")")
      end
    end
  end
end
