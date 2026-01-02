# frozen_string_literal: true

module Notifications
  module Test
    class SidekiqTransientFailure
      CACHE_KEY = 'notifications:test:transient_sidekiq_failure'
      FAILURE_LIMIT = 2

      def self.call
        attempts = Rails.cache.fetch(CACHE_KEY, expires_in: 1.hour) { 0 }
        Rails.cache.write(CACHE_KEY, attempts + 1, expires_in: 1.hour)

        if attempts < FAILURE_LIMIT
          message = "Intentional transient failure attempt #{attempts + 1}"
          Rails.logger.warn "[Notifications::Test::SidekiqTransientFailure] #{message}"
          raise StandardError, message
        end

        Rails.logger.info "[Notifications::Test::SidekiqTransientFailure] succeeded after #{attempts + 1} attempts"
        attempts + 1
      end
    end
  end
end
