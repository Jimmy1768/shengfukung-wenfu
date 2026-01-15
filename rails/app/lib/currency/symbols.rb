# frozen_string_literal: true

require "action_view"

module Currency
  module Symbols
    extend self
    include ActionView::Helpers::NumberHelper

    MAP = {
      "TWD" => "NT$",
      "USD" => "$",
      "EUR" => "€",
      "JPY" => "¥"
    }.freeze

    PRECISION = Hash.new(2).merge(
      "TWD" => 0,
      "JPY" => 0
    ).freeze

    def symbol_for(code)
      return "" if code.blank?

      MAP[code.to_s.upcase] || code.to_s.upcase
    end

    def options
      MAP.map { |code, symbol| ["#{symbol} (#{code})", code] }
    end

    def precision_for(code)
      PRECISION[code.to_s.upcase]
    end

    def format_amount(amount_cents, code)
      amount = amount_cents.to_f / 100.0
      number_to_currency(
        amount,
        unit: symbol_for(code),
        precision: precision_for(code)
      )
    end

    alias_method :for, :symbol_for
  end
end
