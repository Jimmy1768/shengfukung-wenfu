# app/lib/profile/infrastructure.rb
#
# Profile::Infrastructure
# ------------------------------------------------------------------
# Central place for infrastructure / capacity decisions that affect:
# - Puma (web concurrency)
# - Sidekiq / job workers (later)
# - Timeouts / resource limits
#
# These are *defaults* for the Golden Template. Each deployment can
# override them via ENV (WEB_CONCURRENCY, RAILS_MAX_THREADS, etc.).
#
module Profile
  module Infrastructure
    # === WEB SERVER (PUMA) ==================================================
    #
    # Default thread + worker settings for the web process.
    # These should be kept in sync conceptually with config/puma.rb
    # (which uses ENV with numeric fallbacks).
    #

    WEB_MIN_THREADS = 3
    WEB_MAX_THREADS = 5
    WEB_CONCURRENCY = 2

    # === BACKGROUND JOBS (SIDEKIQ, LATER) ===================================
    #
    # Default concurrency for job workers. Sidekiq config can read these
    # as defaults, but still allow ENV overrides.
    #
    JOB_CONCURRENCY = 5

    # === JOB QUEUES ==========================================================
    #
    # Central list of all Sidekiq queues and the order they should be processed
    # in. Job classes refer to these constants so queue names stay in one place.
    #
    module JobQueues
      SYSTEM_TASKS        = :system_tasks
      DAILY               = :daily_jobs
      WEEKLY              = :weekly_jobs
      MONTHLY             = :monthly_jobs
      NOTIFICATIONS_ALERTS = :notifications_alerts

      ORDER = [
        SYSTEM_TASKS,
        DAILY,
        WEEKLY,
        MONTHLY,
        NOTIFICATIONS_ALERTS,
        :default,
        :mailers,
        :low_priority
      ].freeze

      def self.ordered
        ORDER
      end
    end

    # === DATA STORAGE =======================================================
    #
    # Template defaults for database names and ActiveStorage buckets. Client
    # deployments override the actual values via ENV files or deployment manifests.
    #
    module Storage
      DEFAULT_DB_BASE = "golden_template".freeze
      DEFAULT_BUCKET_PREFIX = "golden-template".freeze

      # Public helpers ------------------------------------------------------
      def self.postgres_url(env:)
        env_key = env.to_s.upcase
        ENV["POSTGRES_#{env_key}_URL"] || "postgres://localhost/#{db_name(env: env)}"
      end

      def self.db_name(env:)
        env_key = env.to_s.upcase
        ENV.fetch("POSTGRES_#{env_key}_DB") { default_db_name(env: env) }
      end

      def self.s3_bucket(env:)
        env_key = env.to_s.upcase
        ENV.fetch("S3_BUCKET_#{env_key}") { default_bucket(env: env) }
      end

      # Internal helpers ----------------------------------------------------
      def self.default_db_name(env:)
        case env.to_s
        when "production"
          DEFAULT_DB_BASE
        when "development"
          "#{DEFAULT_DB_BASE}_dev"
        when "test"
          "#{DEFAULT_DB_BASE}_test"
        else
          "#{DEFAULT_DB_BASE}_#{env}"
        end
      end

      def self.default_bucket(env:)
        suffix =
          case env.to_s
          when "production"
            ""
          when "test"
            "-test"
          when "development"
            "-dev"
          else
            "-#{env}"
          end

        "#{DEFAULT_BUCKET_PREFIX}#{suffix}"
      end
    end


    # === TIMEOUTS / LIMITS ==================================================
    #
    # Generic service-level timeouts (HTTP clients, etc.). These are not
    # secrets and can be overridden per deployment if needed.
    #

    REQUEST_TIMEOUT_SECONDS = 15
    EXTERNAL_SERVICE_TIMEOUT_SECONDS = 10
  end
end
