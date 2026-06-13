# frozen_string_literal: true

module Admin
  module FiltersHelper
    def admin_filters_active?(filters)
      filters.any? { |_key, value| value.present? }
    end

    def admin_filter_status_active?(filters, status)
      filters[:status].to_s == status.to_s
    end

    def admin_filter_payment_label(method)
      t("admin.payments.methods.#{method}", default: method.to_s.titleize)
    end

    def admin_payment_source_label(payment)
      t(
        "admin.payments.sources.#{admin_payment_source_key(payment)}",
        provider: admin_filter_payment_label(payment.payment_method.presence || payment.provider),
        default: admin_payment_source_key(payment).to_s.titleize
      )
    end

    def admin_filter_status_label(status, scope: nil)
      return status.to_s.titleize if scope.blank?

      t("#{scope}.#{status}", default: status.to_s.titleize)
    end

    def admin_payment_source_key(payment)
      return :admin_attested_cash if payment.cash? || payment.provider == "manual_cash"
      return :provider_confirmed if payment.completed?
      return :provider_pending if payment.pending?
      return :provider_refunded if payment.refunded?

      :provider_failed
    end
  end
end
