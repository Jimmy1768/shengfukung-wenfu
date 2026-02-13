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
      {
        id: service.id,
        slug: service.slug,
        title: service.title,
        description: service.description.presence || meta[:description].presence ||
          I18n.t("account.services.card.description_fallback"),
        price: formatted_price(service),
        period: meta[:period_label].presence || I18n.t("account.services.card.period_default"),
        status: service.available? ? :open : :closed
      }
    end

    def formatted_price(service)
      Currency::Symbols.format_amount(service.price_cents, service.currency)
    end
  end
end
