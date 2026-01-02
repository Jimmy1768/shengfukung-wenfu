# app/lib/notifications/email_config.rb
#
# Notifications::EmailConfig
# ------------------------------------------------------------------
# Provides a stable interface for notification-related code to access
# email identity configuration.
#
# This module does NOT contain secrets. It simply bridges into the
# Identity namespace for clean separation of concerns.
#
require Rails.root.join("app/lib/profile/identity")

module Notifications
  module EmailConfig
    DEFAULT_SENDER_NAME  = Profile::Identity::DEFAULT_SENDER_NAME
    DEFAULT_SENDER_EMAIL = Profile::Identity::DEFAULT_SENDER_EMAIL

    SUPPORT_EMAIL        = Profile::Identity::SUPPORT_EMAIL
  end
end
