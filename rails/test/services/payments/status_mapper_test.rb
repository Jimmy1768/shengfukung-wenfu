# frozen_string_literal: true

require "test_helper"

module Payments
  class StatusMapperTest < ActiveSupport::TestCase
    test "maps common success and failure aliases" do
      assert_equal TemplePayment::STATUSES[:completed], StatusMapper.map("completed")
      assert_equal TemplePayment::STATUSES[:completed], StatusMapper.map("paid")
      assert_equal TemplePayment::STATUSES[:failed], StatusMapper.map("cancelled")
      assert_equal TemplePayment::STATUSES[:refunded], StatusMapper.map("partial_refunded")
      assert_equal TemplePayment::STATUSES[:pending], StatusMapper.map("processing")
    end

    test "supports custom alias tables and fallback" do
      result = StatusMapper.map(
        "voided",
        aliases: {
          TemplePayment::STATUSES[:failed] => %w[voided]
        },
        fallback: TemplePayment::STATUSES[:pending]
      )

      assert_equal TemplePayment::STATUSES[:failed], result
    end
  end
end
