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

    def start_billing_setup
      result = Billing::StripePaymentMethodSetup.start(
        temple: current_temple,
        admin: current_admin,
        success_url: billing_setup_return_admin_payment_methods_url,
        cancel_url: admin_payment_methods_url
      )

      redirect_to result.url, allow_other_host: true
    rescue StandardError => e
      redirect_to admin_payment_methods_path, alert: t("admin.payment_methods.flash.billing_setup_failed", error: e.message)
    end

    def billing_setup_return
      if params[:checkout_session_id].blank?
        return redirect_to admin_payment_methods_path, alert: t("admin.payment_methods.flash.billing_setup_return_missing")
      end

      Billing::StripePaymentMethodSetup.complete(
        temple: current_temple,
        admin: current_admin,
        checkout_session_id: params[:checkout_session_id]
      )

      redirect_to admin_payment_methods_path, notice: t("admin.payment_methods.flash.billing_setup_completed")
    rescue StandardError => e
      redirect_to admin_payment_methods_path, alert: t("admin.payment_methods.flash.billing_setup_failed", error: e.message)
    end

    private

    def require_owner_admin!
      return if can_manage_admins_for_current_temple?

      redirect_to admin_dashboard_path, alert: t("admin.payment_methods.flash.owner_only")
    end

    def payment_methods_params
      params.require(:payment_methods).permit(
        :ecpay_merchant_id,
        :ecpay_hash_key,
        :ecpay_hash_iv,
        :ecpay_environment,
        :billing_payment_method_on_file
      )
    end
  end
end
