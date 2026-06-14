# frozen_string_literal: true

module ApiProtection
  class AuditMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      return @app.call(env) unless ApiProtection::RequestClassifier.api_request?(request)

      result = audit_request(request)
      return ApiProtection::RequestAudit.rack_response_for(result) if result&.blocked?

      @app.call(env)
    end

    private

    def audit_request(request)
      ApiProtection::RequestAudit.call(request: request)
    rescue => e
      Rails.logger.warn "[ApiProtection::AuditMiddleware] audit skipped #{e.class}: #{e.message}"
      nil
    end
  end
end
