# frozen_string_literal: true

module ApiProtection
  module Policy
    module_function

    DEFAULTS = {
      "api.public.read" => { mode: :audit_only, limit: 300, window_seconds: 60 },
      "api.account.read" => { mode: :audit_only, limit: 240, window_seconds: 60 },
      "api.account.write" => { mode: :enforce, limit: 60, window_seconds: 60 },
      "api.admin.read" => { mode: :audit_only, limit: 180, window_seconds: 60 },
      "api.admin.write" => { mode: :enforce, limit: 45, window_seconds: 60 },
      "web.account.form_submit" => { mode: :audit_only, limit: 20, window_seconds: 60 },
      "web.account.form_submit.contact_temple" => { mode: :enforce, limit: 5, window_seconds: 300 },
      "web.admin.form_submit" => { mode: :audit_only, limit: 30, window_seconds: 60 },
      "api.webhook.ingest" => { mode: :enforce, limit: 120, window_seconds: 60 }
    }.freeze

    def for(endpoint_class)
      DEFAULTS.fetch(endpoint_class, { mode: :audit_only, limit: 60, window_seconds: 60 })
    end
  end
end
