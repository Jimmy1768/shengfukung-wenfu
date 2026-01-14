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
  end
end
