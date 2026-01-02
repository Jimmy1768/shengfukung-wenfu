# frozen_string_literal: true

# Orchestrates pushes, emails, and app messages with clear fallback rules.
module Notifications
  class DispatchEvent
    DEFAULT_DELIVERY_METHODS = %i[push email].freeze

    def initialize(user:, event_key:, title_key: nil, data: {}, params: {}, delivery_methods: DEFAULT_DELIVERY_METHODS, resource_key: nil, locale: nil)
      @user             = user
      @event_key        = event_key
      @title_key        = title_key || event_key
      @data             = data
      @params           = params
      @delivery_methods = Array(delivery_methods)
      @resource_key     = resource_key
      @locale           = locale
    end

    def call
      return {} unless @user

      Rails.logger.info "[Notifications::DispatchEvent] Starting #{delivery_list.inspect} for user=#{@user.id}"
      Notifications::Logging::EventLogger.log(
        event: 'notifications.dispatch.start',
        details: { user_id: @user.id, methods: delivery_list, event_key: @event_key }
      )

      results = {}
      results[:app_message] = app_message_delivery if include?(:app_message)

      if include?(:push)
        results[:push] = push_delivery

        if results[:push] == false && include?(:email)
          Rails.logger.info "[Notifications::DispatchEvent] Push failed; falling back to email for user=#{@user.id}"
          Notifications::Logging::EventLogger.log(
            event: 'notifications.dispatch.push_failed',
            details: { user_id: @user.id, reason: 'push_generation_failed' }
          )

          results[:email] = email_delivery
        end
      elsif include?(:email)
        results[:email] = email_delivery
      end

      Rails.logger.info "[Notifications::DispatchEvent] Completed #{delivery_list.inspect} for user=#{@user.id} #{results.inspect}"
      Notifications::Logging::EventLogger.log(
        event: 'notifications.dispatch.completed',
        details: { user_id: @user.id, results: results }
      )
      results
    rescue => e
      Rails.logger.error "[Notifications::DispatchEvent] Error: #{e.class}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      {}
    end

    private

    def include?(method)
      @delivery_methods.include?(method) && channel_enabled?(method)
    end

    def delivery_list
      @delivery_methods.map(&:to_s).join(',')
    end

    def push_delivery
      with_notification_record(:push) do
        Notifications::Push::Delivery.call(
          user:         @user,
          title_key:    @title_key,
          body_key:     @event_key,
          params:       @params,
          data:         @data,
          locale:       @locale,
          resource_key: @resource_key
        )
      end
    end

    def email_delivery
      with_notification_record(:email) do
        Notifications::Email::Delivery.call(
          user:         @user,
          body_key:     @event_key,
          params:       @params,
          locale:       @locale,
          resource_key: @resource_key
        )
      end
    end

    def app_message_delivery
      with_notification_record(:app_message) do
        Notifications::AppMessage::Delivery.call(
          user:         @user,
          event_key:    @event_key,
          data:         @data,
          params:       @params,
          locale:       @locale,
          resource_key: @resource_key
        )
      end
    end

    def with_notification_record(channel)
      record = nil
      record = Notification.create!(
        notification_rule: notification_rule_for(channel),
        user: @user,
        channel: channel,
        status: "pending",
        recipient: recipient_for(channel),
        message_key: @event_key,
        payload: @data,
        delivery_context: @params,
        scheduled_at: Time.current
      )

      result = yield
      status = result ? "sent" : "failed"
      record.update!(
        status: status,
        sent_at: result ? Time.current : nil,
        failed_at: result ? nil : Time.current
      )
      result
    rescue => e
      record&.update!(
        status: "failed",
        failed_at: Time.current,
        error_details: e.message
      )
      raise
    end

    def notification_rule_for(channel)
      @notification_rules ||= {}
      @notification_rules[channel] ||= NotificationRule.find_by(event_key: @event_key, channel: channel.to_s)
    end

    def channel_enabled?(channel)
      rule = notification_rule_for(channel)
      rule.nil? || rule.enabled?
    end

    def recipient_for(channel)
      case channel
      when :email
        @user&.email
      when :push
        @user&.id&.to_s
      else
        nil
      end
    end
  end
end
