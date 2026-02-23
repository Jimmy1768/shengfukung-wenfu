# frozen_string_literal: true

module Contact
  class TempleInquirySender
    Result = Struct.new(:success?, :error_code, :temple_email, :patron_email, keyword_init: true)

    def initialize(user: nil, temple:, subject:, message:, request_id:, ip:, guest_name: nil, guest_email: nil)
      @user = user
      @temple = temple
      @subject = subject
      @message = message
      @request_id = request_id
      @ip = ip
      @guest_name = guest_name.to_s.strip
      @guest_email = guest_email.to_s.strip
    end

    def call
      patron_email = resolved_patron_email
      unless patron_email.present?
        log(:failed, reason: :missing_user_email)
        return Result.new(success?: false, error_code: :missing_user_email)
      end

      temple_email = resolve_temple_email
      if temple_email.blank?
        log(:failed, reason: :missing_temple_email)
        return Result.new(success?: false, error_code: :missing_temple_email)
      end

      actual_temple_recipient = apply_dev_email_override(temple_email)
      actual_patron_recipient = apply_dev_email_override(patron_email)

      client = Notifications::BrevoClient.new
      delivered_temple = client.send_email(
        to: { email: actual_temple_recipient, name: @temple&.name || "Temple" },
        subject: "【寺廟聯絡】#{@subject}",
        html: Contact::TempleInquiryMailer.temple_notification_html(
          temple_name: @temple&.name || AppConstants::Project.name,
          user_name: patron_display_name,
          user_email: patron_email,
          subject: @subject,
          message: @message,
          submitted_at: Time.current.strftime("%Y-%m-%d %H:%M:%S %Z")
        ),
        sender_name: sender_display_name,
        sender_email: Notifications::EmailConfig::DEFAULT_SENDER_EMAIL
      )
      return failure(:temple_delivery_failed, temple_email:, patron_email:) unless delivered_temple

      delivered_patron = client.send_email(
        to: { email: actual_patron_recipient, name: patron_display_name },
        subject: "我們已收到您的訊息",
        html: Contact::TempleInquiryMailer.patron_ack_html(
          temple_name: @temple&.name || AppConstants::Project.name,
          user_name: patron_display_name,
          subject: @subject
        ),
        sender_name: sender_display_name,
        sender_email: Notifications::EmailConfig::DEFAULT_SENDER_EMAIL
      )
      return failure(:patron_delivery_failed, temple_email:, patron_email:) unless delivered_patron

      log(
        :delivered,
        temple_email: temple_email,
        patron_email: patron_email,
        actual_temple_recipient: actual_temple_recipient,
        actual_patron_recipient: actual_patron_recipient,
        dev_email_override: dev_email_override.presence
      )
      Result.new(success?: true, temple_email:, patron_email:)
    rescue RuntimeError => e
      if e.message.include?("BREVO_API_KEY")
        Rails.logger.error "[Contact::TempleInquirySender] request_id=#{@request_id} missing_brevo_api_key"
        return Result.new(success?: false, error_code: :missing_brevo_api_key)
      end

      Rails.logger.error "[Contact::TempleInquirySender] request_id=#{@request_id} error=#{e.class}: #{e.message}"
      Result.new(success?: false, error_code: :delivery_exception)
    rescue => e
      Rails.logger.error "[Contact::TempleInquirySender] request_id=#{@request_id} error=#{e.class}: #{e.message}"
      Result.new(success?: false, error_code: :delivery_exception)
    end

    private

    def failure(code, temple_email:, patron_email:)
      log(:failed, reason: code, temple_email:, patron_email:, dev_email_override: dev_email_override.presence)
      Result.new(success?: false, error_code: code, temple_email:, patron_email:)
    end

    def patron_display_name
      @guest_name.presence || @user&.native_name.presence || @user&.english_name.presence || resolved_patron_email
    end

    def resolved_patron_email
      @guest_email.presence || @user&.email
    end

    def resolve_temple_email
      details = @temple&.contact_details || {}
      details["email"].presence ||
        details["contactEmail"].presence ||
        AppConstants::Emails.support_email.presence
    end

    def sender_display_name
      temple_name = @temple&.name.to_s.strip
      base_name = Notifications::EmailConfig::DEFAULT_SENDER_NAME.to_s.strip.presence || "TempleMate"
      return base_name if temple_name.blank?

      "#{temple_name} via #{base_name}"
    end

    def dev_email_override
      return nil unless Rails.env.development?

      ENV["DEV_EMAIL"].to_s.strip.presence
    end

    def apply_dev_email_override(actual)
      override = dev_email_override
      return actual unless override

      Rails.logger.info(
        "[Contact::TempleInquirySender] request_id=#{@request_id} dev_email_override intended=#{actual} actual=#{override}"
      )
      override
    end

    def log(result, **extra)
      payload = {
        event: "contact_temple_request.email_delivery",
        result: result,
        request_id: @request_id,
        temple_slug: @temple&.slug,
        user_id: @user&.id,
        ip: @ip
      }.merge(extra.compact)
      Rails.logger.info("[Contact::TempleInquirySender] #{payload.to_json}")
    end
  end
end
