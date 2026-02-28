# frozen_string_literal: true

module Payments
  class ProviderResolver
    PROVIDERS = {
      "fake" => PaymentGateway::FakeAdapter,
      "stripe" => PaymentGateway::StripeAdapter,
      "line_pay" => PaymentGateway::LinePayAdapter
    }.freeze

    def self.resolve(provider: nil)
      key = (provider.presence || ENV.fetch("PAYMENTS_PROVIDER", "fake")).to_s
      adapter_class = PROVIDERS[key]
      raise ArgumentError, "Unsupported payments provider: #{key}" unless adapter_class

      adapter_class.new
    end
  end
end
