# frozen_string_literal: true

module Payments
  class StatusMapper
    DEFAULT_STATUS_ALIASES = {
      TemplePayment::STATUSES[:completed] => %w[succeeded success completed paid],
      TemplePayment::STATUSES[:failed] => %w[failed error declined canceled cancelled],
      TemplePayment::STATUSES[:refunded] => %w[refunded partial_refunded]
    }.freeze

    def self.map(value, aliases: DEFAULT_STATUS_ALIASES, fallback: TemplePayment::STATUSES[:pending])
      status = value.to_s

      aliases.each do |target_status, source_statuses|
        candidates = Array(source_statuses).map(&:to_s) + [target_status.to_s]
        return target_status if candidates.include?(status)
      end

      fallback
    end
  end
end
