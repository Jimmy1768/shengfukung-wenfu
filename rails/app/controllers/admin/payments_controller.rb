# frozen_string_literal: true

module Admin
  class PaymentsController < BaseController
    before_action :require_view_financials!, only: :index
    before_action :require_cash_permissions!, only: %i[new create]
    before_action :require_export_permissions!, only: :export
    before_action :set_registration, only: %i[new create]

    def index
      @payments = base_payment_scope
        .includes(:temple_event_registration, :user, admin_account: :user)
        .order(created_at: :desc)
        .limit(100)
      @payment_summary = Reporting::PaymentSummary.new(payments: base_payment_scope)
      @show_export = current_admin_permissions&.allow?(:export_financials)
    end

    def export
      exporter = Reporting::PaymentsCsvExporter.new(
        payments: base_payment_scope.includes({ temple_event_registration: :temple_offering }, :user, admin_account: :user)
      )
      send_data exporter.to_csv,
        filename: "payments-#{Time.current.strftime('%Y%m%d')}.csv",
        type: "text/csv"
    end

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

    def require_view_financials!
      require_capability!(:view_financials)
    end

    def require_export_permissions!
      require_capability!(:export_financials)
    end

    def set_registration
      @registration = current_temple.temple_event_registrations.find(params[:registration_id])
    end

    def payment_params
      params.require(:temple_payment).permit(:amount_cents, :currency, :notes)
    end

    def base_payment_scope
      current_temple.temple_payments
    end
  end
end
