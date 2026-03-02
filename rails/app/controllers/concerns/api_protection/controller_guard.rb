# frozen_string_literal: true

module ApiProtection
  module ControllerGuard
    extend ActiveSupport::Concern

    private

    def enforce_request_audit!
      return if ApiProtection::RequestClassifier.api_request?(request)

      result = ApiProtection::RequestAudit.call(request: request, current_user: api_protection_current_user)
      return unless result&.blocked?

      redirect_back fallback_location: "/", alert: "Too many requests. Please try again shortly."
    end

    def api_protection_current_user
      if respond_to?(:current_user, true)
        current_user
      elsif respond_to?(:current_admin, true)
        current_admin
      else
        nil
      end
    end
  end
end
