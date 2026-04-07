# frozen_string_literal: true

module Payments
  class EcpayCheckoutsController < ApplicationController
    layout false

    def show
      @payment = TemplePayment.find_by!(provider: "ecpay", provider_reference: params[:payment_reference])
      @checkout_url = @payment.payment_payload.dig("raw", "ecpay_checkout_url").presence
      @form_fields = @payment.payment_payload.dig("raw", "ecpay_form_fields").to_h

      raise ActiveRecord::RecordNotFound if @checkout_url.blank? || @form_fields.blank?
    end
  end
end
