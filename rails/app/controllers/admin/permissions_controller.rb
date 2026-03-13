# frozen_string_literal: true

module Admin
  class PermissionsController < BaseController
    before_action :require_manage_permissions!

    helper Admin::PermissionsHelper if defined?(Admin::PermissionsHelper)

    def index
      @permission_forms = build_permission_forms
    end

    def update
      admin_account = admin_accounts_scope.find(params[:admin_account_id])
      @permission_form = Admin::PermissionForm.new(
        admin_account:,
        temple: current_temple,
        params: permission_params
      )

      if @permission_form.save(current_admin:)
        mark_permissions_reviewed!
        redirect_to admin_permissions_path, notice: t("admin.permissions.flash.updated", name: admin_account.user.english_name)
      else
        @permission_forms = build_permission_forms(overrides: { admin_account.id => @permission_form })
        flash.now[:alert] = t("admin.permissions.flash.review_errors")
        render :index, status: :unprocessable_entity
      end
    end

    private

    def require_manage_permissions!
      require_capability!(:manage_permissions)
    end

    def admin_accounts_scope
      current_temple.admin_accounts
        .staff_role
        .joins(:user)
        .includes(:user)
        .order("users.english_name asc")
    end

    def build_permission_forms(overrides: {})
      admin_accounts_scope.map do |account|
        overrides[account.id] || Admin::PermissionForm.new(admin_account: account, temple: current_temple)
      end
    end

    def permission_params
      params.require(:admin_permission).permit(AdminPermission::CAPABILITIES)
    end

    def mark_permissions_reviewed!
      account = current_admin&.admin_account
      return unless account

      metadata = account.metadata.merge("permissions_reviewed" => true)
      account.update_column(:metadata, metadata)
    end
  end
end
