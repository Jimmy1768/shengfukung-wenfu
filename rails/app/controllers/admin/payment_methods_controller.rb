# frozen_string_literal: true

module Admin
  class PaymentMethodsController < BaseController
    before_action :require_owner_admin!

    def show
      @form = Admin::PaymentMethodsForm.new(temple: current_temple)
    end

    def update
      @form = Admin::PaymentMethodsForm.new(temple: current_temple, params: payment_methods_params)

      if @form.save(current_admin: current_admin)
        redirect_to admin_payment_methods_path, notice: t("admin.payment_methods.flash.updated")
      else
        flash.now[:alert] = t("admin.payment_methods.flash.review_errors")
        render :show, status: :unprocessable_entity
      end
    end

    private

    def require_owner_admin!
      return if current_admin&.admin_account&.owner_role?

      redirect_to admin_dashboard_path, alert: t("admin.payment_methods.flash.owner_only")
    end

    def payment_methods_params
      params.require(:payment_methods).permit(
        :payment_mode,
        :ecpay_merchant_id,
        :ecpay_hash_key,
        :ecpay_hash_iv,
        :ecpay_environment,
        :stripe_platform_enabled,
        :stripe_platform_fee_bps,
        :stripe_platform_notes
      )
    end
  end
end
