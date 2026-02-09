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
        redirect_to account_profile_path, notice: "已新增家屬。"
      else
        flash.now[:alert] = "請確認欄位填寫正確。"
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @form = Account::DependentForm.new(user: current_user, link: @link)
    end

    def update
      @form = Account::DependentForm.new(user: current_user, link: @link, params: dependent_params)
      if @form.save
        redirect_to account_profile_path, notice: "家屬資料已更新。"
      else
        flash.now[:alert] = "請確認欄位填寫正確。"
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @link.destroy
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
  end
end
