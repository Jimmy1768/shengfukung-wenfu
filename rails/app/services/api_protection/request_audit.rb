# frozen_string_literal: true

module ApiProtection
  class RequestAudit
    require "zlib"

    class << self
      def call(request:)
        return unless trackable?(request)

        log_usage(request)
        increment_counter(request)
        enforce_blacklist!(request)
      end

      private

      def trackable?(request)
        request.path.start_with?("/api")
      end

      def log_usage(request)
        ApiUsageLog.create!(
          user: request.env["warden"]&.user,
          access_key: request.get_header("HTTP_AUTHORIZATION"),
          client_identifier: request.get_header("HTTP_USER_AGENT"),
          ip_address: request.ip,
          request_path: request.path,
          http_method: request.request_method,
          status_code: nil,
          response_time_ms: nil,
          occurred_at: Time.current,
          metadata: {}
        )
      rescue => e
        Rails.logger.warn "[ApiProtection::RequestAudit] log error #{e.class}: #{e.message}"
      end

      def increment_counter(request)
        bucket = "#{Time.current.utc.strftime("%Y%m%d%H")}"
        counter = ApiRequestCounter.find_or_initialize_by(
          scope_type: "IpAddress",
          scope_id: scope_identifier(request.ip),
          bucket: bucket
        )
        counter.count = counter.count.to_i + 1
        counter.save!
      rescue => e
        Rails.logger.warn "[ApiProtection::RequestAudit] counter error #{e.class}: #{e.message}"
      end

      def enforce_blacklist!(request)
        return unless BlacklistEntry.where(scope_type: "IpAddress", scope_id: scope_identifier(request.ip), active: true).where("expires_at IS NULL OR expires_at > ?", Time.current).exists?

        body = { error: "rate_limited" }.to_json
        [429, { "Content-Type" => "application/json", "Retry-After" => "60" }, [body]]
      end

      def scope_identifier(ip)
        Zlib.crc32(ip.to_s)
      end
    end
  end
end
