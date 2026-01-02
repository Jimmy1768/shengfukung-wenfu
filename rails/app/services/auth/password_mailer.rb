# frozen_string_literal: true

module Auth
  class PasswordMailer
    def self.reset_email(user:, reset_url:)
      new(user: user, reset_url: reset_url).deliver
    end

    def initialize(user:, reset_url:)
      @user = user
      @reset_url = reset_url
    end

    def deliver
      return false if @user.blank? || @reset_url.blank?

      client = Notifications::BrevoClient.new
      client.send_email(
        to: recipient,
        subject: subject,
        html: body_html,
        sender_name: Notifications::EmailConfig::DEFAULT_SENDER_NAME,
        sender_email: Notifications::EmailConfig::DEFAULT_SENDER_EMAIL
      )
    rescue => e
      Rails.logger.error "[PasswordMailer] Failed to deliver reset email: #{e.class}: #{e.message}"
      false
    end

    private

    def recipient
      {
        email: @user.email,
        name: display_name
      }
    end

    def subject
      I18n.t("account.passwords.mailer.subject", brand: AppConstants::Project.name)
    end

    def body_html
      Notifications::EmailTemplates.password_reset(
        greeting: I18n.t("account.passwords.mailer.greeting", name: display_name),
        intro: I18n.t("account.passwords.mailer.intro"),
        cta_url: @reset_url,
        cta_text: I18n.t("account.passwords.mailer.cta"),
        url_text: @reset_url,
        spam_hint: I18n.t("account.passwords.mailer.spam_hint"),
        copy_hint: I18n.t("account.passwords.mailer.copy_hint"),
        ignore_notice: I18n.t("account.passwords.mailer.ignore_notice"),
        signoff_html: I18n.t("account.passwords.mailer.signoff_html", brand: AppConstants::Project.name)
      )
    end

    def display_name
      @user.english_name.presence || @user.email
    end
  end
end
