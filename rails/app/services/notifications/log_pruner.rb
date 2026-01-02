# frozen_string_literal: true

require 'fileutils'

module Notifications
  class LogPruner
    LOG_DIR = Rails.root.join('log', 'notifications')
    KEEP_DAYS = (ENV['NOTIFICATIONS_LOG_KEEP_DAYS'] || 60).to_i

    def self.call
      return unless LOG_DIR.directory?

      cutoff_time = KEEP_DAYS.days.ago
      Dir.glob(LOG_DIR.join('*.log')).each do |path|
        file_mtime = File.mtime(path)
        if file_mtime < cutoff_time
          FileUtils.rm_f(path)
          Rails.logger.info "[Notifications::LogPruner] Removed log #{path} older than #{KEEP_DAYS} days"
        end
      end
    rescue => e
      Rails.logger.error "[Notifications::LogPruner] cleanup failed: #{e.class}: #{e.message}"
    end
  end
end
