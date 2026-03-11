# frozen_string_literal: true

module Internal
  class TempleAccessController < BaseController
    before_action :set_temple, only: %i[grant revoke]

    def index
      @temples = Temple.order(:name)
      @memberships_by_temple_id = current_admin.admin_account.admin_temple_memberships.index_by(&:temple_id)
    end

    def grant
      role = normalized_role
      stored_role = stored_membership_role(role)
      admin_account = current_admin.admin_account
      membership = admin_account.admin_temple_memberships.find_or_initialize_by(temple: @temple)
      previous_role = membership.role

      AdminTempleMembership.transaction do
        membership.role = stored_role
        membership.save!

        permission = AdminPermission.find_or_initialize_by(admin_account:, temple: @temple)
        apply_permission_defaults!(permission, role)
        permission.save!
      end

      SystemAuditLogger.log!(
        action: "internal.temple_access.grant_#{role}",
        admin: current_admin,
        target: @temple,
        temple: @temple,
        metadata: {
          previous_role: previous_role,
          resulting_role: stored_role,
          requested_role: role,
          admin_account_id: admin_account.id
        }
      )

      redirect_to internal_temple_access_path, notice: "#{@temple.name}: granted #{role} access."
    end

    def revoke
      admin_account = current_admin.admin_account
      membership = admin_account.admin_temple_memberships.find_by(temple: @temple)

      unless membership
        return redirect_to internal_temple_access_path, alert: "#{@temple.name}: no access to revoke."
      end

      previous_role = membership.role

      AdminTempleMembership.transaction do
        AdminPermission.where(admin_account:, temple: @temple).delete_all
        membership.destroy!
      end

      SystemAuditLogger.log!(
        action: "internal.temple_access.revoke",
        admin: current_admin,
        target: @temple,
        temple: @temple,
        metadata: {
          previous_role: previous_role,
          admin_account_id: admin_account.id
        }
      )

      redirect_to internal_temple_access_path, notice: "#{@temple.name}: access revoked."
    end

    private

    def set_temple
      @temple = Temple.find(params[:temple_id])
    end

    def normalized_role
      role = params[:role].to_s
      return role if %w[owner admin].include?(role)

      raise ActionController::BadRequest, "Unsupported role"
    end

    def apply_permission_defaults!(permission, role)
      AdminPermission::CAPABILITIES.each do |capability|
        permission[capability] = permission_enabled_for_role?(capability, role)
      end
    end

    def stored_membership_role(role)
      role == "admin" ? "staff" : role
    end

    def permission_enabled_for_role?(capability, role)
      return true if role == "owner"
      return false if capability == :manage_permissions

      true
    end
  end
end
