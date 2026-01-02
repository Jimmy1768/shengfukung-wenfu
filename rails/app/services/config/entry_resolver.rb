# frozen_string_literal: true

module Config
  # Central read/write helper for ConfigEntry records so controllers/services
  # don't need to juggle scope attrs or defaults.
  class EntryResolver
    class << self
      def fetch(key, scope: nil, default: nil)
        entry = ConfigEntry.find_by(**lookup_attrs(key, scope: scope))
        entry ? entry.value : default
      end

      def fetch_flag(key, scope: nil, default: false)
        value = fetch(key, scope: scope)
        return default if value.nil?

        ActiveModel::Type::Boolean.new.cast(value)
      end

      def upsert!(key:, value:, scope: nil, description: nil, metadata: {})
        attrs = lookup_attrs(key, scope: scope)
        ConfigEntry.find_or_initialize_by(attrs).tap do |entry|
          entry.value = value
          entry.description = description if description
          entry.metadata = (entry.metadata || {}).merge(metadata || {})
          entry.save!
        end
      end

      private

      def lookup_attrs(key, scope:)
        if scope
          {
            key: key,
            scope_type: scope.class.name,
            scope_id: scope.id
          }
        else
          { key: key, scope_type: "system", scope_id: nil }
        end
      end
    end
  end
end
