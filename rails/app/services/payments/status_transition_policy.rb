# frozen_string_literal: true

module Payments
  class StatusTransitionPolicy
    class InvalidTransition < StandardError; end

    ALLOWED_TRANSITIONS = {
      TemplePayment::STATUSES[:pending] => [
        TemplePayment::STATUSES[:pending],
        TemplePayment::STATUSES[:completed],
        TemplePayment::STATUSES[:failed]
      ].freeze,
      TemplePayment::STATUSES[:completed] => [
        TemplePayment::STATUSES[:completed],
        TemplePayment::STATUSES[:refunded]
      ].freeze,
      TemplePayment::STATUSES[:failed] => [TemplePayment::STATUSES[:failed]].freeze,
      TemplePayment::STATUSES[:refunded] => [TemplePayment::STATUSES[:refunded]].freeze
    }.freeze

    def self.assert!(from:, to:)
      return if from.blank?

      allowed = ALLOWED_TRANSITIONS[from] || []
      return if allowed.include?(to)

      raise InvalidTransition, "Invalid payment status transition: #{from} -> #{to}"
    end
  end
end
