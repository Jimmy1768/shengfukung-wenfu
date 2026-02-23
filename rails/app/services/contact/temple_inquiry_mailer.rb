# frozen_string_literal: true

require "erb"

module Contact
  class TempleInquiryMailer
    class << self
      def temple_notification_html(temple_name:, user_name:, user_email:, subject:, message:, submitted_at:)
        body_html = <<~HTML
          <p>A new contact request was submitted from the account portal.</p>
          <p><strong>Temple:</strong> #{esc(temple_name)}</p>
          <p><strong>Patron:</strong> #{esc(user_name)}</p>
          <p><strong>Email:</strong> <a href="mailto:#{esc(user_email)}">#{esc(user_email)}</a></p>
          <p><strong>Submitted at:</strong> #{esc(submitted_at)}</p>
          <p><strong>Subject:</strong> #{esc(subject)}</p>
          <p><strong>Message:</strong><br />#{format_multiline(message)}</p>
        HTML

        Notifications::EmailTemplates.standard_layout(body_html)
      end

      def patron_ack_html(temple_name:, user_name:, subject:)
        body_html = <<~HTML
          <p>Hello #{esc(user_name)},</p>
          <p>We received your message for #{esc(temple_name)}.</p>
          <p><strong>Subject:</strong> #{esc(subject)}</p>
          <p>The temple team will review your inquiry and reply by email when available.</p>
          <p style="margin-top: 16px;">Thank you.</p>
        HTML

        Notifications::EmailTemplates.standard_layout(body_html)
      end

      private

      def format_multiline(text)
        esc(text).gsub("\n", "<br />")
      end

      def esc(value)
        ERB::Util.html_escape(value.to_s)
      end
    end
  end
end
