# frozen_string_literal: true

namespace :db do
  namespace :seed do
    desc "Seed auth core data"
    task auth_core: :environment do
      require Rails.root.join("db", "seeds", "auth_core")
      Seeds::AuthCore.seed
    end

    desc "Seed session preferences data"
    task session_preferences: :environment do
      require Rails.root.join("db", "seeds", "session_preferences")
      Seeds::SessionPreferences.seed
    end

    desc "Seed messaging data"
    task messaging: :environment do
      require Rails.root.join("db", "seeds", "messaging")
      Seeds::Messaging.seed
    end

    desc "Seed admin control data"
    task admin_controls: :environment do
      require Rails.root.join("db", "seeds", "admin_controls")
      Seeds::AdminControls.seed
    end

    desc "Seed cache control data"
    task cache_control: :environment do
      require Rails.root.join("db", "seeds", "cache_control")
      Seeds::CacheControl.seed
    end

    desc "Seed record archive data"
    task record_archives: :environment do
      require Rails.root.join("db", "seeds", "record_archives")
      Seeds::RecordArchives.seed
    end

    desc "Seed configuration entries data"
    task config_entries: :environment do
      require Rails.root.join("db", "seeds", "config_entries")
      Seeds::ConfigEntries.seed
    end

    desc "Seed background task registry data"
    task background_tasks: :environment do
      require Rails.root.join("db", "seeds", "background_tasks")
      Seeds::BackgroundTasks.seed
    end

    desc "Seed API protection data"
    task api_protection: :environment do
      require Rails.root.join("db", "seeds", "api_protection")
      Seeds::ApiProtection.seed
    end

    desc "Seed compliance data"
    task compliance: :environment do
      require Rails.root.join("db", "seeds", "compliance")
      Seeds::Compliance.seed
    end

    desc "Seed analytics export data"
    task analytics_exports: :environment do
      require Rails.root.join("db", "seeds", "analytics_exports")
      Seeds::AnalyticsExports.seed
    end
  end
end
