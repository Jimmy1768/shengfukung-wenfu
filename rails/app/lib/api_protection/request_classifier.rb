# frozen_string_literal: true

module ApiProtection
  module RequestClassifier
    module_function

    API_PATTERN = %r{\A/api/}.freeze

    def classify(request)
      method = request.request_method
      path = request.path

      if api_path?(path)
        return "api.webhook.ingest" if method == "POST" && path.match?(%r{\A/api/v1/payments/webhooks/})
        return "api.account.write" if method != "GET" && path.match?(%r{\A/api/v1/account/})
        return "api.account.read" if method == "GET" && path.match?(%r{\A/api/v1/account/})
        return "api.public.read" if method == "GET"
        return "api.account.write"
      end

      return "web.account.form_submit.contact_temple" if method == "POST" && path == "/account/contact_temple_requests"
      return "web.account.form_submit" if account_write_path?(method, path)
      return "web.admin.form_submit" if admin_write_path?(method, path)

      nil
    end

    def api_path?(path)
      path.match?(API_PATTERN)
    end

    def api_request?(request)
      api_path?(request.path)
    end

    def account_write_path?(method, path)
      return false unless %w[POST PATCH PUT DELETE].include?(method)
      return false unless path.start_with?("/account")

      true
    end

    def admin_write_path?(method, path)
      return false unless %w[POST PATCH PUT DELETE].include?(method)
      return false unless path.start_with?("/admin")

      true
    end
  end
end
