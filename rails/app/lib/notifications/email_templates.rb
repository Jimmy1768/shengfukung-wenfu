# frozen_string_literal: true

require 'erb'

module Notifications
  module EmailTemplates
    DEFAULT_WRAPPER_STYLE = 'font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;font-size:16px;line-height:1.5;color:#111;'
    DEFAULT_BUTTON_STYLE  = 'display:inline-block;padding:10px 14px;background:#1f6feb;color:#fff;text-decoration:none;border-radius:6px;'

    module_function

    # Basic layout for reusable content blocks.
    def standard_layout(content)
      <<~HTML
        <div style="#{DEFAULT_WRAPPER_STYLE}">
          #{content}
        </div>
      HTML
    end

    # CTA button helper for templates that need a primary action.
    def cta_button(text:, url:)
      <<~HTML
        <p style="margin:12px 0 0;">
          <a href="#{esc(url)}" style="#{DEFAULT_BUTTON_STYLE}">
            #{esc(text)}
          </a>
        </p>
      HTML
    end

    # Simple push notification layout.
    def push_notification(greeting:, body:, footer:, cta_url:, cta_text:)
      standard_layout(<<~HTML)
        <p style="margin:0 0 12px;">#{esc(greeting)},</p>
        <p style="margin:0 0 12px;">#{esc(body)}</p>
        #{cta_button(text: cta_text, url: cta_url)}
        <p style="margin:16px 0 0;color:#666;font-size:14px;">#{esc(footer)}</p>
      HTML
    end

    # Password reset template with CTA plus extra guidance copy.
    def password_reset(greeting:, intro:, cta_url:, cta_text:, url_text:, spam_hint:, copy_hint:, ignore_notice:, signoff_html:)
      standard_layout(<<~HTML)
        <p>#{esc(greeting)}</p>
        <p>#{esc(intro)}</p>
        #{cta_button(text: cta_text, url: cta_url)}
        <p style="margin:6px 0 0;word-break:break-all;">#{esc(url_text)}</p>
        <p style="margin:10px 0 0;color:#666;font-size:14px;">#{esc(spam_hint)}</p>
        <p style="margin:10px 0 0;color:#444;font-size:14px;">#{esc(copy_hint)}</p>
        <p style="margin:16px 0 0;color:#666;">#{esc(ignore_notice)}</p>
        <p style="margin:16px 0 0;">#{signoff_html}</p>
      HTML
    end

    def marketing_template(body_html:, footer_text: nil)
      footer = footer_text.present? ? "<p style=\"margin:16px 0 0;color:#666;font-size:14px;\">#{esc(footer_text)}</p>" : ''
      standard_layout(<<~HTML)
        #{body_html}
        #{footer}
      HTML
    end

    def esc(value)
      ERB::Util.html_escape(value.to_s)
    end
  end
end
