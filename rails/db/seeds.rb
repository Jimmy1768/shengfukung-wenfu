# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
require_relative "seeds/auth_core"
require_relative "seeds/session_preferences"
require_relative "seeds/messaging"
require_relative "seeds/temples"
require_relative "seeds/admin_controls"
require_relative "seeds/cache_control"
require_relative "seeds/record_archives"
require_relative "seeds/config_entries"
require_relative "seeds/background_tasks"
require_relative "seeds/api_protection"
require_relative "seeds/compliance"
require_relative "seeds/analytics_exports"
require_relative "seeds/temple_demo_users"

Seeds::AuthCore.seed
Seeds::SessionPreferences.seed
Seeds::Messaging.seed
Seeds::Temples.seed
Seeds::AdminControls.seed
Seeds::CacheControl.seed
Seeds::RecordArchives.seed
Seeds::ConfigEntries.seed
Seeds::BackgroundTasks.seed
Seeds::ApiProtection.seed
Seeds::Compliance.seed
Seeds::AnalyticsExports.seed
Seeds::TempleDemoUsers.seed

if Rails.env.test?
  puts "Seeding test fixtures..." # rubocop:disable Rails/Output
  User.find_or_create_by!(email: "test+spec@#{AppConstants::Project.slug}.local") do |user|
    user.english_name = "Test Fixture"
    user.encrypted_password = User.password_hash("TestPassword!123")
    user.metadata = (user.metadata || {}).merge(seed_context: "test_env")
  end

  DevModeToken.find_or_create_by!(
    admin_account: AdminAccount.first!,
    purpose: "test-suite"
  ) do |token|
    token.token = "test-suite-token"
    token.metadata = token.metadata.merge(seed_context: "test_env") if token.metadata
  end
end
