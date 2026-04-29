# frozen_string_literal: true

require "cgi"

module Billing
  class StripePaymentMethodSetup
    Result = Struct.new(:session_id, :url, :payload, keyword_init: true)

    def self.start(...)
      new(...).start
    end

    def self.complete(...)
      new(...).complete
    end

    def initialize(temple:, admin:, success_url: nil, cancel_url: nil, checkout_session_id: nil)
      @temple = temple
      @admin = admin
      @success_url = success_url
      @cancel_url = cancel_url
      @checkout_session_id = checkout_session_id
    end

    def start
      ensure_configured!

      session = Stripe::Checkout::Session.create({
        mode: "setup",
        customer: billing_settings["stripe_customer_id"].presence,
        customer_email: billing_settings["stripe_customer_id"].present? ? nil : admin.email,
        client_reference_id: temple.id.to_s,
        success_url: append_checkout_session_id(success_url),
        cancel_url: cancel_url,
        setup_intent_data: { metadata: metadata },
        metadata: metadata
      }.compact)

      Result.new(session_id: session.id, url: session.url, payload: session.to_hash)
    end

    def complete
      ensure_configured!

      session = Stripe::Checkout::Session.retrieve(
        id: checkout_session_id,
        expand: ["setup_intent.payment_method", "customer"]
      )
      setup_intent = session.setup_intent
      payment_method = setup_intent.respond_to?(:payment_method) ? setup_intent.payment_method : nil
      customer = session.customer
      card = payment_method&.card

      raise ArgumentError, "Stripe did not return a saved payment method" if payment_method.blank?

      payment_settings = temple.payment_provider_settings.is_a?(Hash) ? temple.payment_provider_settings.deep_dup : {}
      payment_settings["billing"] = billing_settings.merge(
        "payment_method_on_file" => true,
        "provider" => "stripe",
        "stripe_customer_id" => customer.respond_to?(:id) ? customer.id : session.customer,
        "stripe_payment_method_id" => payment_method.id,
        "stripe_setup_intent_id" => setup_intent.respond_to?(:id) ? setup_intent.id : session.setup_intent,
        "card_brand" => card&.brand,
        "card_last4" => card&.last4,
        "card_exp_month" => card&.exp_month,
        "card_exp_year" => card&.exp_year,
        "monthly_fee_cents" => Admin::PaymentMethodsForm::DEFAULT_BILLING_MONTHLY_FEE_CENTS,
        "grace_days" => Admin::PaymentMethodsForm::DEFAULT_BILLING_GRACE_DAYS,
        "grace_started_at" => nil,
        "last_setup_at" => Time.current.iso8601,
        "last_stripe_checkout_session_id" => session.id
      ).compact

      Temple.transaction do
        temple.update!(payment_provider_settings: payment_settings)
        SystemAuditLogger.log!(
          action: "admin.payment_methods.billing_setup_completed",
          admin: admin,
          target: temple,
          temple: temple,
          metadata: {
            provider: "stripe",
            stripe_customer_id: payment_settings.dig("billing", "stripe_customer_id"),
            stripe_payment_method_id: payment_method.id,
            card_brand: card&.brand,
            card_last4: card&.last4
          }.compact
        )
      end

      Result.new(session_id: session.id, url: nil, payload: session.to_hash)
    end

    private

    attr_reader :temple, :admin, :success_url, :cancel_url, :checkout_session_id

    def ensure_configured!
      raise ArgumentError, "STRIPE_SECRET_KEY is not configured" if Rails.configuration.x.stripe.secret_key.blank?
    end

    def billing_settings
      @billing_settings ||= temple.billing_settings
    end

    def metadata
      {
        temple_id: temple.id,
        temple_slug: temple.slug,
        admin_id: admin.id,
        purpose: "templemate_platform_billing_method"
      }
    end

    def append_checkout_session_id(url)
      uri = URI.parse(url)
      params = CGI.parse(uri.query.to_s).transform_values { |values| values.last }
      params["checkout_session_id"] = "{CHECKOUT_SESSION_ID}"
      uri.query = params.map do |key, value|
        encoded_key = CGI.escape(key.to_s)
        encoded_value = value.to_s == "{CHECKOUT_SESSION_ID}" ? value.to_s : CGI.escape(value.to_s)
        "#{encoded_key}=#{encoded_value}"
      end.join("&")
      uri.to_s
    end
  end
end
