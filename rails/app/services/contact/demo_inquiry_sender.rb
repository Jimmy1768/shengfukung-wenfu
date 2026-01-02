# frozen_string_literal: true

require 'erb'

module Contact
  class DemoInquirySender
    Result = Struct.new(:success?, :locale_key, :error_code, keyword_init: true)

    def initialize(email:, name:, locale_code:, message:, metadata: {})
      @recipient_email = email.to_s.strip
      @recipient_name  = name.to_s.strip
      @locale_code     = locale_code.presence || AppConstants::Locales::DEFAULT_CODE
      @message         = message.to_s.strip
      # Metadata contains client + server context for the admin email. Everything is symbolized
      # once so the renderer can access values predictably.
      @metadata        = metadata.to_h.deep_symbolize_keys
    end

    def call
      return failure(:invalid_email) unless valid_email?

      locale_entry = AppConstants::Locales.find(@locale_code)
      locale_key   = locale_entry[:locale_key]&.to_sym || I18n.default_locale

      client = Notifications::BrevoClient.new

      admin_sent = deliver_admin_copy(client, locale_key: locale_key)
      return failure(:delivery_failed, locale_key: locale_key) unless admin_sent

      auto_reply_sent = deliver_auto_reply(client, locale_key: locale_key)
      return failure(:delivery_failed, locale_key: locale_key) unless auto_reply_sent

      Result.new(success?: true, locale_key: locale_key)
    rescue RuntimeError => e
      if e.message.include?("BREVO_API_KEY")
        Rails.logger.error "[Contact::DemoInquirySender] Missing Brevo API key: #{e.message}"
        failure(:missing_brevo, locale_key: locale_key)
      else
        Rails.logger.error "[Contact::DemoInquirySender] Error: #{e.class}: #{e.message}"
        failure(:delivery_failed, locale_key: locale_key)
      end
    rescue StandardError => e
      Rails.logger.error "[Contact::DemoInquirySender] Error: #{e.class}: #{e.message}"
      failure(:delivery_failed)
    end

    private

    def deliver_admin_copy(client, locale_key:)
      contact_name = display_name
      client.send_email(
        to:           { email: AppConstants::Emails.contact_inbox, name: 'Sourcegrid Labs' },
        subject:      "New demo inquiry from #{contact_name}",
        html:         admin_email_html(locale_key: locale_key),
        sender_name:  Notifications::EmailConfig::DEFAULT_SENDER_NAME,
        sender_email: Notifications::EmailConfig::DEFAULT_SENDER_EMAIL
      )
    end

    def deliver_auto_reply(client, locale_key:)
      subject = I18n.t(
        "demo_admin.contact.demo_auto_reply.subject",
        locale: locale_key,
        brand: AppConstants::Project.name
      )

      client.send_email(
        to:           { email: @recipient_email, name: display_name },
        subject:      subject,
        html:         build_auto_reply_html(locale_key: locale_key),
        sender_name:  Notifications::EmailConfig::DEFAULT_SENDER_NAME,
        sender_email: Notifications::EmailConfig::DEFAULT_SENDER_EMAIL
      )
    end

    def build_auto_reply_html(locale_key:)
      greeting = I18n.t("demo_admin.contact.demo_auto_reply.greeting", locale: locale_key, name: display_name)
      intro    = I18n.t("demo_admin.contact.demo_auto_reply.intro", locale: locale_key)
      closing  = I18n.t("demo_admin.contact.demo_auto_reply.closing", locale: locale_key)
      signature = I18n.t(
        "demo_admin.contact.demo_auto_reply.signature",
        locale: locale_key,
        brand: AppConstants::Project.name
      )

      body_html = <<~HTML
        <p>#{greeting}</p>
        <p>#{intro}</p>
        <p style="margin-top:16px;">#{closing}<br />#{signature}</p>
      HTML

      Notifications::EmailTemplates.standard_layout(body_html)
    end

    def safe_text(value)
      ERB::Util.html_escape(value.to_s)
    end

    def formatted_message
      text = @message.presence || I18n.t('demo_admin.contact.demo_auto_reply.no_message', default: 'No additional details were provided.')
      safe_text(text).gsub(/\n/, '<br />')
    end

    def admin_email_html(locale_key:)
      Contact::DemoInquiryMailer.admin_html(
        name: display_name,
        email: @recipient_email,
        locale_key: locale_key,
        message_html: formatted_message,
        metadata: @metadata
      )
    end

    def valid_email?
      @recipient_email.present? && URI::MailTo::EMAIL_REGEXP.match?(@recipient_email)
    end

    def display_name
      return @recipient_name if @recipient_name.present?

      I18n.t("demo_admin.contact.demo_auto_reply.default_name", default: "there")
    end

    def failure(code, locale_key: I18n.default_locale)
      Result.new(success?: false, locale_key: locale_key, error_code: code)
    end
  end
end
