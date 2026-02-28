# frozen_string_literal: true

require "test_helper"

module Payments
  class StatusTransitionPolicyTest < ActiveSupport::TestCase
    test "allows pending to completed" do
      assert_nothing_raised do
        StatusTransitionPolicy.assert!(
          from: TemplePayment::STATUSES[:pending],
          to: TemplePayment::STATUSES[:completed]
        )
      end
    end

    test "blocks refunded to completed" do
      assert_raises(StatusTransitionPolicy::InvalidTransition) do
        StatusTransitionPolicy.assert!(
          from: TemplePayment::STATUSES[:refunded],
          to: TemplePayment::STATUSES[:completed]
        )
      end
    end
  end
end
