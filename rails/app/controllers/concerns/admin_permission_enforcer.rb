# frozen_string_literal: true

module AdminPermissionEnforcer
  extend ActiveSupport::Concern

  included do
    helper_method :current_admin_permissions, :can_manage_admins_for_current_temple?
  end

  def require_capability!(capability)
    return if current_admin_permissions&.allow?(capability)

    redirect_to admin_dashboard_path, alert: "You do not have access to #{capability.to_s.humanize(capitalize: false)}."
  end

  def current_admin_permissions
    return nil unless current_admin&.admin_account

    @current_admin_permissions ||= current_admin.admin_account.permissions_for(current_temple)
  end

  def can_manage_admins_for_current_temple?
    current_admin_permissions&.allow?(:manage_permissions) || false
  end
end
