# frozen_string_literal: true

module Admin
  class PaymentsController < BaseController
    before_action :require_view_financials!, only: :index
    before_action :require_cash_permissions!, only: %i[new create]
    before_action :require_export_permissions!, only: :export
    before_action :set_registration, only: %i[new create]

    def index
      @filters = normalized_filter_params
      apply_default_payment_range!
      scoped = filtered_payments_scope
      @payments = scoped
        .order(Arel.sql("COALESCE(temple_payments.processed_at, temple_payments.created_at) DESC"))
        .limit(200)
      @payment_summary = Reporting::PaymentSummary.new(payments: scoped)
      @show_export = current_admin_permissions&.allow?(:export_financials)
      @filter_offerings = current_temple.temple_offerings.order(:title)
      @filter_payment_methods = TemplePayment::PAYMENT_METHODS.values
      @filter_hidden_fields = filter_hidden_params
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

    def apply_default_payment_range!
      return if @filters[:start_date].present? || @filters[:end_date].present?

      @filters[:start_date] = 90.days.ago.to_date.iso8601
      @default_payment_window = true
    end

    def filtered_payments_scope
      base_payment_scope.merge(TemplePayment.admin_filtered(@filters))
    end
  end
end
