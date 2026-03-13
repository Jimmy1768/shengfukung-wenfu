# frozen_string_literal: true

module Admin
  class PaymentsController < BaseController
    helper_method :payment_month_presets

    before_action :require_view_financials!, only: :index
    before_action :require_cash_permissions!, only: %i[new create fake_checkout]
    before_action :require_export_permissions!, only: :export
    before_action :prepare_payment_filters, only: %i[index export]
    before_action :set_registration, only: %i[new create fake_checkout]

    def index
      apply_month_preset!
      apply_default_payment_range!
      scoped = filtered_payments_scope
      @payments = scoped
        .order(Arel.sql("COALESCE(temple_payments.processed_at, temple_payments.created_at) DESC"))
        .limit(200)
      @payment_summary = Reporting::PaymentSummary.new(payments: scoped)
      @show_export = current_admin_permissions&.allow?(:export_financials)
      @filter_offerings = [
        current_temple.temple_events.order(:title),
        current_temple.temple_services.order(:title),
        current_temple.temple_gatherings.order(:title)
      ].flat_map(&:to_a)
      @filter_payment_methods = TemplePayment::PAYMENT_METHODS.values
      @filter_statuses = TemplePayment::STATUSES.values
      @filter_hidden_fields = filter_hidden_params
    end

    def export
      exporter = Reporting::PaymentsCsvExporter.new(
        payments: filtered_payments_scope.includes(:temple_registration, :user, admin_account: :user)
      )
      send_data exporter.to_csv,
        filename: export_filename,
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

      redirect_to offering_order_path(@registration.offering, @registration),
        notice: t("admin.payments.flash.recorded")
    rescue ActiveRecord::RecordInvalid => e
      @payment = e.record
      render :new, status: :unprocessable_entity
    end

    def fake_checkout
      result = Payments::CheckoutService.new.call(
        registration: @registration,
        amount_cents: @registration.total_price_cents,
        currency: @registration.currency,
        provider: "fake",
        idempotency_key: fake_idempotency_key,
        intent_key: "registration:#{@registration.id}",
        metadata: {
          source: "admin_console",
          temple_slug: current_temple.slug
        }
      )

      notice = if result.reused
                 t("admin.payments.flash.fake_checkout_reused")
               else
                 t("admin.payments.flash.fake_checkout_started")
               end
      redirect_to offering_order_path(@registration.offering, @registration), notice: notice
    rescue StandardError => e
      redirect_to offering_order_path(@registration.offering, @registration), alert: t("admin.payments.flash.fake_checkout_failed", error: e.message)
    end

    private

    def prepare_payment_filters
      @filters = normalized_filter_params
    end

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

    def apply_month_preset!
      return if @filters[:start_date].present? || @filters[:end_date].present?

      preset = payment_month_presets.find { |entry| entry[:key] == @filters[:month_preset].to_s }
      return unless preset

      @filters[:start_date] = preset[:filters][:start_date]
      @filters[:end_date] = preset[:filters][:end_date]
    end

    def payment_month_presets
      [
        {
          key: "this_month",
          label: I18n.t("admin.payments.index.presets.this_month"),
          filters: preset_filters_for(Time.zone.today.beginning_of_month.to_date, Time.zone.today.end_of_month.to_date)
        },
        {
          key: "last_month",
          label: I18n.t("admin.payments.index.presets.last_month"),
          filters: preset_filters_for(1.month.ago.beginning_of_month.to_date, 1.month.ago.end_of_month.to_date)
        }
      ]
    end

    def filtered_payments_scope
      base_payment_scope.merge(TemplePayment.admin_filtered(@filters))
    end

    def export_filename
      scope =
        if @filters[:start_date].present? && @filters[:end_date].present?
          "#{@filters[:start_date]}-to-#{@filters[:end_date]}"
        elsif @filters[:query].present?
          @filters[:query].parameterize(separator: "-").presence || "filtered"
        else
          Time.current.strftime("%Y%m%d")
        end

      "payments-#{scope}-#{Time.current.strftime('%Y%m%d')}.csv"
    end

    def offering_order_path(offering, registration)
      return admin_event_offering_order_path(offering, registration) if offering.is_a?(TempleEvent)
      return admin_service_offering_order_path(offering, registration) if offering.is_a?(TempleService)
      return admin_gathering_offering_order_path(offering, registration) if offering.is_a?(TempleGathering)

      admin_orders_path
    end

    def fake_idempotency_key
      params[:idempotency_key].presence || "admin-reg-#{@registration.id}-#{SecureRandom.hex(4)}"
    end

    def preset_filters_for(start_date, end_date)
      filter_params.except(:start_date, :end_date, :month_preset).merge(
        start_date: start_date.iso8601,
        end_date: end_date.iso8601
      )
    end
  end
end
