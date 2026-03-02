# frozen_string_literal: true

module ApiProtection
  class RequestAudit
    require "zlib"
    Result = Struct.new(:blocked, :decision, :endpoint_class, :reason, :retry_after, keyword_init: true) do
      def blocked?
        blocked
      end
    end

    class << self
      def call(request:, current_user: nil)
        endpoint_class = RequestClassifier.classify(request)
        return unless endpoint_class

        identity = resolve_identity(request, current_user)
        policy = Policy.for(endpoint_class)

        result = enforce_blacklist!(identity, endpoint_class, policy)
        if result
          log_usage(request, endpoint_class: endpoint_class, identity: identity, policy: policy, result: result)
          return result
        end

        counter = increment_counter(request, endpoint_class: endpoint_class, identity: identity)
        throttled = throttled?(counter: counter, policy: policy)
        result = if throttled
          Result.new(
            blocked: true,
            decision: "throttle",
            endpoint_class: endpoint_class,
            reason: "limit_exceeded",
            retry_after: policy.fetch(:window_seconds)
          )
        else
          Result.new(blocked: false, decision: policy.fetch(:mode).to_s, endpoint_class: endpoint_class, reason: "ok")
        end

        log_usage(request, endpoint_class: endpoint_class, identity: identity, policy: policy, result: result)
        result
      end

      def rack_response_for(result)
        retry_after = result.retry_after || 60
        body = { error: "rate_limited", reason: result.reason }.to_json
        [429, { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s }, [body]]
      end

      private

      def log_usage(request, endpoint_class:, identity:, policy:, result:)
        ApiUsageLog.create!(
          user: identity[:user],
          access_key: request.get_header("HTTP_AUTHORIZATION"),
          client_identifier: request.get_header("HTTP_USER_AGENT"),
          ip_address: request.ip,
          request_path: request.path,
          http_method: request.request_method,
          status_code: result.blocked? ? 429 : nil,
          response_time_ms: nil,
          occurred_at: Time.current,
          metadata: {
            endpoint_class: endpoint_class,
            decision: result.decision,
            reason: result.reason,
            mode: policy.fetch(:mode),
            limit: policy.fetch(:limit),
            window_seconds: policy.fetch(:window_seconds),
            scope_type: identity[:scope_type],
            scope_id: identity[:scope_id]
          }
        )
      rescue => e
        Rails.logger.warn "[ApiProtection::RequestAudit] log error #{e.class}: #{e.message}"
      end

      def increment_counter(request, endpoint_class:, identity:)
        bucket = "#{minute_bucket}:#{endpoint_class}:#{request.request_method}"
        counter = ApiRequestCounter.find_or_initialize_by(
          scope_type: identity[:scope_type],
          scope_id: identity[:scope_id],
          bucket: bucket
        )
        counter.count = counter.count.to_i + 1
        counter.metadata = counter.metadata.merge("endpoint_class" => endpoint_class, "request_method" => request.request_method)
        counter.save!
        counter
      rescue => e
        Rails.logger.warn "[ApiProtection::RequestAudit] counter error #{e.class}: #{e.message}"
        nil
      end

      def enforce_blacklist!(identity, endpoint_class, policy)
        return unless blacklisted?(scope_type: identity[:scope_type], scope_id: identity[:scope_id]) ||
                      blacklisted?(scope_type: "IpAddress", scope_id: identity[:ip_scope_id])

        Result.new(
          blocked: true,
          decision: "blacklist_deny",
          endpoint_class: endpoint_class,
          reason: "blacklist",
          retry_after: policy.fetch(:window_seconds)
        )
      end

      def blacklisted?(scope_type:, scope_id:)
        return false if scope_id.blank?

        BlacklistEntry.where(scope_type: scope_type, scope_id: scope_id, active: true)
          .where("expires_at IS NULL OR expires_at > ?", Time.current)
          .exists?
      end

      def throttled?(counter:, policy:)
        return false unless policy.fetch(:mode) == :enforce
        return false unless counter

        counter.count > policy.fetch(:limit)
      end

      def resolve_identity(request, current_user)
        user = current_user || request.env["warden"]&.user
        user_id = user.respond_to?(:id) ? user.id : user
        ip_scope_id = scope_identifier(request.ip)

        if user_id.present?
          { user: user.respond_to?(:id) ? user : nil, scope_type: "User", scope_id: user_id, ip_scope_id: ip_scope_id }
        else
          { user: nil, scope_type: "IpAddress", scope_id: ip_scope_id, ip_scope_id: ip_scope_id }
        end
      end

      def minute_bucket
        Time.current.utc.strftime("%Y%m%d%H%M")
      end

      def scope_identifier(raw)
        Zlib.crc32(raw.to_s)
      end
    end
  end
end
