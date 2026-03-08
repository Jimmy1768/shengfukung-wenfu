# frozen_string_literal: true

require "zlib"

module FeatureFlags
  class Evaluator
    class << self
      def enabled?(key, actor: nil, scope: nil, default: false)
        entry = ConfigEntry.includes(:feature_flag_rollout).find_by(lookup_attrs(key, scope))
        return default if entry.blank?

        base_enabled = ActiveModel::Type::Boolean.new.cast(entry.value)
        rollout = entry.feature_flag_rollout
        return base_enabled if rollout.blank?
        return false unless within_window?(rollout)
        return false if rollout.prerequisite_key.present? && !enabled?(rollout.prerequisite_key, actor: actor, scope: scope, default: false)

        return base_enabled unless actor.present?
        return false unless base_enabled

        bucket(actor, key) < rollout.rollout_percentage.to_i
      end

      private

      def lookup_attrs(key, scope)
        if scope
          { key: key, scope_type: scope.class.name, scope_id: scope.id }
        else
          { key: key, scope_type: "system", scope_id: nil }
        end
      end

      def within_window?(rollout)
        now = Time.current
        return false if rollout.starts_at.present? && now < rollout.starts_at
        return false if rollout.ends_at.present? && now > rollout.ends_at

        true
      end

      def bucket(actor, key)
        source =
          if actor.respond_to?(:id) && actor.id.present?
            actor.id
          elsif actor.respond_to?(:email) && actor.email.present?
            actor.email
          else
            actor.to_s
          end

        Zlib.crc32("#{key}:#{source}") % 100
      end
    end
  end
end
