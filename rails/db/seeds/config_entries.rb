# frozen_string_literal: true

module Seeds
  module ConfigEntries
    extend self

    DEFAULT_ENTRIES = [
      {
        key: "feature:admin-task-queue",
        value: { ready: true },
        description: "Controls whether demo admins can trigger Sidekiq probes.",
        metadata: { seeded: true },
        feature_flag: {
          enabled_by_default: true,
          rollout_percentage: 80,
          prerequisite_key: nil
        }
      }
    ].freeze

    def seed
      puts "Seeding config entries..." # rubocop:disable Rails/Output
      DEFAULT_ENTRIES.each do |entry|
        config = ConfigEntry.find_or_initialize_by(
          key: entry[:key],
          scope_type: "system",
          scope_id: nil
        )

        config.assign_attributes(
          value: entry[:value],
          description: entry[:description],
          metadata: (config.metadata || {}).merge(entry[:metadata] || {}).merge(seed_metadata)
        )
        config.save! if config.changed?
        seed_feature_flag_rollout(config, entry[:feature_flag]) if entry[:feature_flag]
      end
    end

    private

    def seed_feature_flag_rollout(config_entry, flag_attrs)
      FeatureFlagRollout.find_or_initialize_by(config_entry: config_entry).tap do |rollout|
        rollout.enabled_by_default = flag_attrs[:enabled_by_default]
        rollout.rollout_percentage = flag_attrs[:rollout_percentage]
        rollout.prerequisite_key = flag_attrs[:prerequisite_key]
        rollout.metadata = (rollout.metadata || {}).merge(seed_metadata)
        rollout.save! if rollout.changed?
      end
    end

    def seed_metadata
      {
        seeded_at: Time.current.iso8601,
        seeded_by: "db:seed:config_entries"
      }
    end
  end
end
