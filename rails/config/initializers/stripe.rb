# frozen_string_literal: true

Rails.application.configure do
  config.x.stripe = ActiveSupport::OrderedOptions.new unless config.x.respond_to?(:stripe)
  config.x.stripe.secret_key = ENV["STRIPE_SECRET_KEY"]
  config.x.stripe.publishable_key = ENV["STRIPE_PUBLISHABLE_KEY"]
end

if defined?(Stripe)
  Stripe.api_key = Rails.configuration.x.stripe.secret_key
  Stripe.api_version = "2026-02-25.clover"
end
