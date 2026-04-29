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
        mode: "subscription",
        customer: billing_settings["stripe_customer_id"].presence,
        customer_email: billing_settings["stripe_customer_id"].present? ? nil : admin.email,
        client_reference_id: temple.id.to_s,
        success_url: append_checkout_session_id(success_url),
        cancel_url: cancel_url,
        line_items: [line_item],
        subscription_data: {
          metadata: metadata
        },
        metadata: metadata
      }.compact)

      Result.new(session_id: session.id, url: session.url, payload: session.to_hash)
    end

    def complete
      ensure_configured!

      session = Stripe::Checkout::Session.retrieve(
        id: checkout_session_id,
        expand: [
          "customer",
          "customer.invoice_settings.default_payment_method",
          "subscription",
          "subscription.default_payment_method"
        ]
      )
      subscription = session.respond_to?(:subscription) ? session.subscription : nil
      customer = session.customer
      payment_method = extract_payment_method(subscription, customer)
      card = payment_method&.card

      raise ArgumentError, "Stripe did not return a subscription" if subscription.blank?

      payment_settings = temple.payment_provider_settings.is_a?(Hash) ? temple.payment_provider_settings.deep_dup : {}
      payment_settings["billing"] = billing_settings.merge(
        "payment_method_on_file" => true,
        "provider" => "stripe",
        "stripe_customer_id" => customer.respond_to?(:id) ? customer.id : session.customer,
        "stripe_subscription_id" => subscription.respond_to?(:id) ? subscription.id : session.subscription,
        "stripe_payment_method_id" => payment_method&.id,
        "card_brand" => card&.brand,
        "card_last4" => card&.last4,
        "card_exp_month" => card&.exp_month,
        "card_exp_year" => card&.exp_year,
        "monthly_fee_cents" => Admin::PaymentMethodsForm::DEFAULT_BILLING_MONTHLY_FEE_CENTS,
        "billing_interval" => "year",
        "billing_interval_months" => Admin::PaymentMethodsForm::DEFAULT_BILLING_INTERVAL_MONTHS,
        "annual_fee_cents" => Admin::PaymentMethodsForm::DEFAULT_BILLING_MONTHLY_FEE_CENTS * Admin::PaymentMethodsForm::DEFAULT_BILLING_INTERVAL_MONTHS,
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
            stripe_subscription_id: payment_settings.dig("billing", "stripe_subscription_id"),
            stripe_payment_method_id: payment_method&.id,
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
        purpose: "templemate_platform_subscription",
        monthly_fee_cents: Admin::PaymentMethodsForm::DEFAULT_BILLING_MONTHLY_FEE_CENTS,
        annual_fee_cents: Admin::PaymentMethodsForm::DEFAULT_BILLING_MONTHLY_FEE_CENTS * Admin::PaymentMethodsForm::DEFAULT_BILLING_INTERVAL_MONTHS,
        billing_interval: "year"
      }
    end

    def line_item
      if ENV["STRIPE_TEMPLEMATE_PLATFORM_PRICE_ID"].present?
        return {
          price: ENV.fetch("STRIPE_TEMPLEMATE_PLATFORM_PRICE_ID"),
          quantity: 1
        }
      end

      {
        quantity: 1,
        price_data: {
          currency: "twd",
          unit_amount: Admin::PaymentMethodsForm::DEFAULT_BILLING_MONTHLY_FEE_CENTS * Admin::PaymentMethodsForm::DEFAULT_BILLING_INTERVAL_MONTHS,
          recurring: { interval: "year" },
          product_data: {
            name: "TempleMate Platform",
            description: "NT$3,000 per month, billed yearly"
          }
        }
      }
    end

    def extract_payment_method(subscription, customer)
      subscription_payment_method =
        subscription.default_payment_method if subscription.respond_to?(:default_payment_method)
      return subscription_payment_method if subscription_payment_method.respond_to?(:id)

      invoice_settings = customer.invoice_settings if customer.respond_to?(:invoice_settings)
      customer_payment_method =
        invoice_settings.default_payment_method if invoice_settings.respond_to?(:default_payment_method)
      customer_payment_method if customer_payment_method.respond_to?(:id)
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
