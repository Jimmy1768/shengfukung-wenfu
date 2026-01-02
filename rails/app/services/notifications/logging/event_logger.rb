# frozen_string_literal: true

require 'fileutils'
require 'json'

module Notifications
  module Logging
    class EventLogger
      LOG_DIR = Rails.root.join('log', 'notifications')
      FILE_DATE_FORMAT = '%Y-%m-%d'

      def self.log(event:, level: :info, details: {})
        details = details.transform_values { |value| sanitize_value(value) }
        payload = {
          timestamp: Time.now.utc.iso8601,
          level:     level,
          event:     event,
          details:   details
        }

        ensure_log_dir
        file_path = LOG_DIR.join("#{Date.today.strftime(FILE_DATE_FORMAT)}.log")
        File.open(file_path, 'a') { |f| f.puts(payload.to_json) }
        Rails.logger.send(level, "[Notifications::Logging] #{payload[:event]} #{details.inspect}")
      rescue => e
        Rails.logger.error "[Notifications::Logging::EventLogger] write failed: #{e.class}: #{e.message}"
      end

      def self.ensure_log_dir
        FileUtils.mkdir_p(LOG_DIR) unless Dir.exist?(LOG_DIR)
      end

      def self.sanitize_value(value)
        case value
        when String, Symbol, Numeric, TrueClass, FalseClass, NilClass
          value
        else
          value.to_s
        end
      end
    end
  end
end
