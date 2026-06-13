# frozen_string_literal: true

require "test_helper"

module Payments
  class ProviderResolverTest < ActiveSupport::TestCase
    test "test environment defaults to fake checkout" do
      with_env("PAYMENTS_PROVIDER" => nil) do
        assert_equal "fake", ProviderResolver.current_provider
        assert_instance_of PaymentGateway::FakeAdapter, ProviderResolver.resolve
      end
    end

    test "non-test local environments default to ecpay" do
      with_env("PAYMENTS_PROVIDER" => nil) do
        Rails.env.stub(:test?, false) do
          assert_equal "ecpay", ProviderResolver.current_provider
          assert_instance_of PaymentGateway::EcpayAdapter, ProviderResolver.resolve
        end
      end
    end

    test "explicit provider override wins" do
      with_env("PAYMENTS_PROVIDER" => "fake") do
        Rails.env.stub(:test?, false) do
          assert_equal "fake", ProviderResolver.current_provider
        end
      end
    end

    private

    def with_env(overrides)
      original = overrides.each_with_object({}) { |(key, _), result| result[key] = ENV[key] }
      overrides.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
      yield
    ensure
      original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    end
  end
end
