# frozen_string_literal: true

module Notifications
  module Test
    class SidekiqFatalFailure
      class FatalTestError < StandardError; end

      def self.call
        message = 'Intentional fatal failure (no retries left)'
        Rails.logger.warn "[Notifications::Test::SidekiqFatalFailure] #{message}"
        raise FatalTestError, message
      end
    end
  end
end
