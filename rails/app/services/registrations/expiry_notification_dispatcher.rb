# frozen_string_literal: true

module Registrations
  class ExpiryNotificationDispatcher
    EXPIRING_SOON_EVENT = "registration.expiring_soon"
    EXPIRED_EVENT = "registration.expired"
    EXPIRING_SOON_WINDOW = 24.hours

    class << self
      def dispatch_expiring_soon!(now: Time.current)
        pending_candidates_for_expiring_soon(now:).find_each do |registration|
          next if notification_sent?(registration, EXPIRING_SOON_EVENT)

          notify_registration_event!(registration:, event_key: EXPIRING_SOON_EVENT, now:)
        end
      end

      def dispatch_expired!(now: Time.current)
        recently_expired_candidates(now:).find_each do |registration|
          next if notification_sent?(registration, EXPIRED_EVENT)

          notify_registration_event!(registration:, event_key: EXPIRED_EVENT, now:)
        end
      end

      private

      def pending_candidates_for_expiring_soon(now:)
        TempleRegistration
          .includes(temple: { admin_accounts: :user }, user: nil)
          .where(payment_status: TempleRegistration::PAYMENT_STATUSES[:pending], fulfillment_status: TempleRegistration::FULFILLMENT_STATUSES[:open])
          .where("total_price_cents > 0")
          .where.not(expires_at: nil)
          .where("expires_at > ? AND expires_at <= ?", now, now + EXPIRING_SOON_WINDOW)
      end

      def recently_expired_candidates(now:)
        TempleRegistration
          .includes(temple: { admin_accounts: :user }, user: nil)
          .where(payment_status: TempleRegistration::PAYMENT_STATUSES[:pending], fulfillment_status: TempleRegistration::FULFILLMENT_STATUSES[:cancelled])
          .where.not(cancelled_at: nil)
          .where("cancelled_at >= ?", now - 25.hours)
      end

      def notify_registration_event!(registration:, event_key:, now:)
        recipients = recipients_for(registration.temple, registration.user)
        return if recipients.empty?

        recipients.each do |recipient|
          send_email_notification!(
            user: recipient,
            registration: registration,
            event_key: event_key,
            now: now
          )
        end

        mark_notification_sent!(registration, event_key, now)
      end

      def recipients_for(temple, patron_user)
        admins = temple.admin_accounts.active.includes(:user).map(&:user).compact
        [patron_user, *admins].compact.uniq(&:id)
      end

      def send_email_notification!(user:, registration:, event_key:, now:)
        return unless email_enabled_for?(user:, event_key:)

        rule = NotificationRule.find_by(event_key:, channel: "email")
        notification = Notification.create!(
          notification_rule: rule,
          user: user,
          channel: "email",
          status: "pending",
          recipient: recipient_email_for(user),
          message_key: event_key,
          payload: {
            reference_code: registration.reference_code,
            temple_slug: registration.temple.slug
          },
          delivery_context: {
            event_key: event_key,
            registration_id: registration.id
          },
          scheduled_at: now
        )

        sent = Notifications::BrevoClient.new.send_email(
          to: { email: recipient_email_for(user), name: user.english_name.presence || user.email },
          subject: email_subject(event_key),
          html: email_html(event_key:, registration:, recipient_name: user.english_name.presence || user.email),
          sender_name: Notifications::EmailConfig::DEFAULT_SENDER_NAME,
          sender_email: Notifications::EmailConfig::DEFAULT_SENDER_EMAIL
        )

        notification.update!(
          status: sent ? "sent" : "failed",
          sent_at: (sent ? now : nil),
          failed_at: (sent ? nil : now),
          error_details: (sent ? nil : "brevo_send_false")
        )
      rescue StandardError => e
        notification&.update!(
          status: "failed",
          failed_at: now,
          error_details: e.message
        )
      end

      def email_enabled_for?(user:, event_key:)
        rule = NotificationRule.find_by(event_key:, channel: "email")
        return false if rule&.enabled == false

        preference = NotificationPreference.find_by(user:, channel: "email")
        return false if preference&.enabled == false
        return false if rule&.requires_opt_in && preference.nil?

        true
      end

      def notification_sent?(registration, event_key)
        registration.metadata.to_h.dig("expiry_notifications", event_key).present?
      end

      def mark_notification_sent!(registration, event_key, now)
        data = (registration.metadata || {}).deep_dup
        expiry_metadata = (data["expiry_notifications"] || {}).deep_dup
        expiry_metadata[event_key] = now.iso8601
        data["expiry_notifications"] = expiry_metadata
        registration.update_columns(metadata: data, updated_at: now)
      end

      def recipient_email_for(user)
        return AppConstants::Emails.dev_app_notification_email if Rails.env.development?

        user.email
      end

      def email_subject(event_key)
        case event_key
        when EXPIRING_SOON_EVENT
          "報名保留即將到期提醒"
        when EXPIRED_EVENT
          "報名保留已到期通知"
        else
          "報名狀態通知"
        end
      end

      def email_html(event_key:, registration:, recipient_name:)
        temple_name = registration.temple.name
        reference = registration.reference_code
        expires_at = registration.expires_at || registration.cancelled_at
        body = case event_key
               when EXPIRING_SOON_EVENT
                 <<~HTML
                   <p>您好 #{Notifications::EmailTemplates.esc(recipient_name)}：</p>
                   <p>您的報名保留即將到期。</p>
                   <p><strong>宮廟：</strong>#{Notifications::EmailTemplates.esc(temple_name)}</p>
                   <p><strong>報名編號：</strong>#{Notifications::EmailTemplates.esc(reference)}</p>
                   <p><strong>到期時間：</strong>#{Notifications::EmailTemplates.esc(expires_at&.in_time_zone&.strftime("%Y-%m-%d %H:%M"))}</p>
                 HTML
               else
                 <<~HTML
                   <p>您好 #{Notifications::EmailTemplates.esc(recipient_name)}：</p>
                   <p>您的未付款報名保留已到期並自動取消。</p>
                   <p><strong>宮廟：</strong>#{Notifications::EmailTemplates.esc(temple_name)}</p>
                   <p><strong>報名編號：</strong>#{Notifications::EmailTemplates.esc(reference)}</p>
                   <p><strong>取消時間：</strong>#{Notifications::EmailTemplates.esc(expires_at&.in_time_zone&.strftime("%Y-%m-%d %H:%M"))}</p>
                 HTML
               end

        Notifications::EmailTemplates.standard_layout(body)
      end
    end
  end
end

