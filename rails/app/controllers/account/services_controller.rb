# frozen_string_literal: true

module Account
  class ServicesController < BaseController
    def index
      @services = services_scope.map { |service| build_service_card(service) }
    end

    private

    def services_scope
      current_temple.temple_services
        .published_visible
        .order(:title)
    end

    def build_service_card(service)
      meta = (service.metadata || {}).with_indifferent_access
      period_key = service.registration_period_key.presence
      resolved_period =
        if period_key.present?
          current_temple.registration_period_label_for(period_key)
        else
          service.period_label.presence || meta[:period_label].presence
        end
      {
        id: service.id,
        slug: service.slug,
        title: service.title,
        # Patron cards should reflect the temple admin's saved offering copy, not template metadata.
        description: service.description.presence,
        price: formatted_price(service),
        period: resolved_period.presence || I18n.t("account.services.card.period_default"),
        status: service.available? ? :open : :closed
      }
    end

    def formatted_price(service)
      Currency::Symbols.format_amount(service.price_cents, service.currency)
    end
  end
end
