
# app/workers/notifications/push_worker.rb
#
# Sidekiq worker responsible for sending a single push notification
# to a specific device.
#
# NOTE:
# - This worker should be "dumb" and delegate complex logic to services.
module Notifications
  class PushWorker
    include Sidekiq::Worker

    # @param device_token [String]
    # @param platform [String] e.g. "ios", "android", "expo"
    # @param title [String]
    # @param body [String]
    # @param data [Hash]
    def perform(device_token, platform, title, body, data = {})
      # TODO: call Notifications::PushService using the given params.
      raise NotImplementedError, "Notifications::PushWorker#perform is not implemented yet"
    end
  end
end
