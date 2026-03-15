# frozen_string_literal: true

module Admin
  class PatronAdminManager
    class Error < StandardError; end

    def promote!(user:, temple:, promoted_by:)
      raise Error, I18n.t("admin.patrons.flash.invalid_user") unless user

      admin_account = ensure_admin_account(user)
      ensure_membership!(admin_account:, temple:)
      log_action!(admin_account:, temple:, actor: promoted_by, action: "promote")
      true
    end

    def revoke!(user:, temple:, revoked_by:)
      raise Error, I18n.t("admin.patrons.flash.invalid_user") unless user

      admin_account = user.admin_account
      raise Error, I18n.t("admin.patrons.flash.not_admin") unless admin_account
      raise Error, I18n.t("admin.patrons.flash.cannot_remove_owner") if admin_account.owner_role?

      membership = admin_account.admin_temple_memberships.find_by(temple:)
      raise Error, I18n.t("admin.patrons.flash.not_admin") unless membership

      membership.destroy!
      admin_account.admin_permissions.where(temple:).destroy_all
      log_action!(admin_account:, temple:, actor: revoked_by, action: "revoke")
      true
    end

    private

    def ensure_admin_account(user)
      admin = user.admin_account || user.build_admin_account(role: :admin, active: true)
      admin.active = true
      admin.role ||= :admin
      admin.save! if admin.changed?
      admin
    end

    def ensure_membership!(admin_account:, temple:)
      AdminTempleMembership.find_or_create_by!(admin_account:, temple:, role: admin_account.role)
      AdminPermission.find_or_create_by!(admin_account:, temple:)
    end

    def log_action!(admin_account:, temple:, actor:, action:)
      return unless actor

      SystemAuditLogger.log!(
        action: "admin.patrons.#{action}",
        admin: actor,
        target: admin_account.user,
        metadata: {
          admin_account_id: admin_account.id,
          temple_id: temple.id,
          action: action
        },
        temple: temple
      )
    end
  end
end
