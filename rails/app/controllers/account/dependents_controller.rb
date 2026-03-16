# frozen_string_literal: true

module Account
  class DependentsController < BaseController
    before_action :set_link, only: %i[edit update destroy]

    def new
      @form = Account::DependentForm.new(user: current_user)
    end

    def create
      @form = Account::DependentForm.new(user: current_user, params: dependent_params)
      if @form.save
        log_dependent_event!("account.dependents.created", target: @form.link&.dependent, changed_fields: dependent_params.keys)
        redirect_to account_profile_path, notice: "已新增家屬。"
      else
        flash.now[:alert] = "請確認欄位填寫正確。"
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @form = Account::DependentForm.new(user: current_user, link: @link)
    end

    def update
      @form = Account::DependentForm.new(user: current_user, link: @link, params: dependent_params)
      if @form.save
        log_dependent_event!("account.dependents.updated", target: @form.link&.dependent, changed_fields: dependent_params.keys)
        redirect_to account_profile_path, notice: "家屬資料已更新。"
      else
        flash.now[:alert] = "請確認欄位填寫正確。"
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      dependent = @link.dependent
      @link.destroy
      log_dependent_event!("account.dependents.deleted", target: dependent, changed_fields: [])
      redirect_to account_profile_path, notice: "家屬已刪除。"
    end

    private

    def set_link
      @link = current_user.user_dependents.includes(:dependent).find(params[:id])
    end

    def dependent_params
      params.require(:account_dependent_form).permit(
        :english_name,
        :native_name,
        :relationship_label,
        :birthdate,
        :phone,
        :email,
        :notes
      )
    end

    def log_dependent_event!(action, target:, changed_fields:)
      SystemAuditLogger.log!(
        action: action,
        admin: current_user,
        target: target,
        temple: current_temple,
        metadata: {
          actor_type: "user",
          changed_fields: Array(changed_fields).map(&:to_s)
        }
      )
    end
  end
end
