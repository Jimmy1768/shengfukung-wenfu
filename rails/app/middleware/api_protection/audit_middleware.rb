# frozen_string_literal: true

module ApiProtection
  class AuditMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      return @app.call(env) unless ApiProtection::RequestClassifier.api_request?(request)

      result = ApiProtection::RequestAudit.call(request: request)
      return ApiProtection::RequestAudit.rack_response_for(result) if result&.blocked?

      @app.call(env)
    end
  end
end
