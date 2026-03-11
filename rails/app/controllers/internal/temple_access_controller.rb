# frozen_string_literal: true

module Internal
  class TempleAccessController < BaseController
    before_action :set_temple, only: %i[show grant promote_owner revoke]
    before_action :set_target_membership, only: :promote_owner

    def index
      @temples = Temple.order(:name)
      @memberships_by_temple_id = current_admin.admin_account.admin_temple_memberships.index_by(&:temple_id)
    end

    def show
      @temple_admin_memberships = AdminTempleMembership
        .includes(admin_account: %i[user admin_permissions])
        .joins(admin_account: :user)
        .where(temple: @temple)
        .order(Arel.sql("users.english_name ASC NULLS LAST, users.email ASC"))
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

    def promote_owner
      admin_account = @target_membership.admin_account
      previous_role = @target_membership.role

      if previous_role == "owner"
        return redirect_to internal_temple_access_temple_path(@temple), alert: "#{admin_account.user.email} is already an owner."
      end

      AdminTempleMembership.transaction do
        @target_membership.update!(role: "owner")

        permission = AdminPermission.find_or_initialize_by(admin_account:, temple: @temple)
        apply_permission_defaults!(permission, "owner")
        permission.save!
      end

      SystemAuditLogger.log!(
        action: "internal.temple_access.promote_owner",
        admin: current_admin,
        target: admin_account.user,
        temple: @temple,
        metadata: {
          previous_role: previous_role,
          resulting_role: "owner",
          admin_account_id: admin_account.id,
          target_user_id: admin_account.user_id
        }
      )

      redirect_to internal_temple_access_temple_path(@temple), notice: "#{admin_account.user.email}: promoted to owner."
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

    def set_target_membership
      @target_membership = AdminTempleMembership.find_by!(temple: @temple, admin_account_id: params[:admin_account_id])
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
