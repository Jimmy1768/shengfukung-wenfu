# frozen_string_literal: true

module Admin
  module PermissionsHelper
    def capability_label(capability)
      I18n.t("admin.permissions.capabilities.#{capability}.label", default: capability.to_s.humanize)
    end

    def capability_hint(capability)
      I18n.t("admin.permissions.capabilities.#{capability}.hint", default: "")
    end
  end
end
