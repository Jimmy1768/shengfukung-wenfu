# frozen_string_literal: true

module Admin
  class PaymentsController < BaseController
    before_action :require_cash_permissions!
    before_action :set_registration

    def new
      @payment = @registration.temple_payments.new(
        payment_method: TemplePayment::PAYMENT_METHODS[:cash],
        currency: @registration.currency,
        amount_cents: @registration.total_price_cents
      )
    end

    def create
      recorder = Payments::CashPaymentRecorder.new(
        registration: @registration,
        admin_user: current_admin,
        amount_cents: payment_params[:amount_cents].to_i,
        currency: payment_params[:currency],
        notes: payment_params[:notes]
      )
      @payment = recorder.record!

      redirect_to admin_offering_offering_order_path(@registration.temple_offering, @registration),
        notice: "Payment recorded."
    rescue ActiveRecord::RecordInvalid => e
      @payment = e.record
      render :new, status: :unprocessable_entity
    end

    private

    def require_cash_permissions!
      require_capability!(:record_cash_payments)
    end

    def set_registration
      @registration = current_temple.temple_event_registrations.find(params[:registration_id])
    end

    def payment_params
      params.require(:temple_payment).permit(:amount_cents, :currency, :notes)
    end
  end
end
