# frozen_string_literal: true

module ApiProtection
  class AuditMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      block_response = ApiProtection::RequestAudit.call(request: request)
      return block_response if block_response

      @app.call(env)
    end
  end
end
