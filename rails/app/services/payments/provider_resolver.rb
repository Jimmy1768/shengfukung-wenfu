# frozen_string_literal: true

module Payments
  class ProviderResolver
    PROVIDERS = {
      "fake" => PaymentGateway::FakeAdapter,
      "ecpay" => PaymentGateway::EcpayAdapter
    }.freeze

    PROVIDER_LABELS = {
      "fake" => "test checkout",
      "ecpay" => "ECPay"
    }.freeze

    def self.current_provider
      ENV.fetch("PAYMENTS_PROVIDER", Rails.env.test? ? "fake" : "ecpay").to_s
    end

    def self.label_for(provider)
      PROVIDER_LABELS.fetch(provider.to_s, provider.to_s.humanize)
    end

    def self.resolve(provider: nil, temple: nil)
      key = (provider.presence || current_provider).to_s
      adapter_class = PROVIDERS[key]
      raise ArgumentError, "Unsupported payments provider: #{key}" unless adapter_class

      if adapter_class.instance_method(:initialize).parameters.any? { |type, name| [:key, :keyreq].include?(type) && name == :temple }
        adapter_class.new(temple: temple)
      else
        adapter_class.new
      end
    end
  end
end
