# frozen_string_literal: true

Rails.application.configure do
  config.x.ecpay = ActiveSupport::OrderedOptions.new unless config.x.respond_to?(:ecpay)
  config.x.ecpay.environment = ENV.fetch("ECPAY_ENVIRONMENT", Rails.env.production? ? "production" : "stage")
end
