# frozen_string_literal: true

require "erb"

module Contact
  class TempleInquiryMailer
    class << self
      def temple_notification_html(temple_name:, user_name:, user_email:, subject:, message:, submitted_at:)
        body_html = <<~HTML
          <p>收到一則新的聯絡詢問。</p>
          <p><strong>寺廟：</strong>#{esc(temple_name)}</p>
          <p><strong>聯絡人：</strong>#{esc(user_name)}</p>
          <p><strong>Email:</strong> <a href="mailto:#{esc(user_email)}">#{esc(user_email)}</a></p>
          <p><strong>送出時間：</strong>#{esc(submitted_at)}</p>
          <p><strong>主旨：</strong>#{esc(subject)}</p>
          <p><strong>訊息內容：</strong><br />#{format_multiline(message)}</p>
        HTML

        Notifications::EmailTemplates.standard_layout(body_html)
      end

      def patron_ack_html(temple_name:, user_name:, subject:)
        body_html = <<~HTML
          <p>您好，#{esc(user_name)}：</p>
          <p>我們已收到您寄給 #{esc(temple_name)} 的訊息。</p>
          <p><strong>主旨：</strong>#{esc(subject)}</p>
          <p>寺方會在可回覆時以 Email 與您聯繫，回覆時間可能依工作情況有所不同。</p>
          <p style="margin-top: 16px;">感謝您的來信。</p>
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
