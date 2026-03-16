# frozen_string_literal: true

module Payments
  class ProviderResolver
    PROVIDERS = {
      "fake" => PaymentGateway::FakeAdapter,
      "stripe" => PaymentGateway::StripeAdapter,
      "line_pay" => PaymentGateway::LinePayAdapter
    }.freeze

    PROVIDER_LABELS = {
      "fake" => "test checkout",
      "stripe" => "Stripe",
      "line_pay" => "LINE Pay"
    }.freeze

    def self.current_provider
      ENV.fetch("PAYMENTS_PROVIDER", "fake").to_s
    end

    def self.label_for(provider)
      PROVIDER_LABELS.fetch(provider.to_s, provider.to_s.humanize)
    end

    def self.resolve(provider: nil)
      key = (provider.presence || current_provider).to_s
      adapter_class = PROVIDERS[key]
      raise ArgumentError, "Unsupported payments provider: #{key}" unless adapter_class

      adapter_class.new
    end
  end
end
