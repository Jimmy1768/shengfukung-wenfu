# frozen_string_literal: true

require 'erb'

module Contact
  # Builds HTML fragments for demo inquiry emails so we can keep
  # layout/metadata rendering isolated from the sender logic.
  class DemoInquiryMailer
    class << self
      def admin_html(name:, email:, locale_key:, message_html:, metadata: {})
        intro = 'A new inquiry was submitted from the Sourcegrid demo showcase.'

        body_html = <<~HTML
          <p>#{intro}</p>
          <p><strong>Name:</strong> #{escape(name)}</p>
          <p><strong>Email:</strong> <a href="mailto:#{escape(email)}">#{escape(email)}</a></p>
          <p><strong>Locale:</strong> #{escape(locale_key)}</p>
          <p><strong>Message:</strong><br />#{message_html}</p>
          #{metadata_section(metadata)}
        HTML

        Notifications::EmailTemplates.standard_layout(body_html)
      end

      private

      def metadata_section(metadata)
        return '' if metadata.blank?

        client_block = metadata_block('Client context', metadata[:client])
        server_block = metadata_block('Server context', metadata[:server])

        return '' if client_block.blank? && server_block.blank?

        <<~HTML
          <hr style="margin:24px 0; border:none; border-top:1px solid rgba(148,163,184,0.3);" />
          #{client_block}
          #{server_block}
        HTML
      end

      def metadata_block(title, data)
        return '' if data.blank?

        rows = data.map do |key, value|
          <<~HTML
            <tr>
              <td style="padding:4px 12px 4px 0; font-weight:600; white-space:nowrap;">#{escape(key)}</td>
              <td style="padding:4px 0;">#{format_value(value)}</td>
            </tr>
          HTML
        end.join

        <<~HTML
          <p style="margin: 0 0 4px;"><strong>#{escape(title)}</strong></p>
          <table style="border-collapse:collapse; margin-bottom:12px;">#{rows}</table>
        HTML
      end

      def format_value(value)
        stringified = value.respond_to?(:strftime) ? value.strftime('%Y-%m-%d %H:%M:%S %Z') : value.to_s
        stringified.present? ? escape(stringified) : '&mdash;'
      end

      def escape(value)
        ERB::Util.html_escape(value.to_s)
      end
    end
  end
end
