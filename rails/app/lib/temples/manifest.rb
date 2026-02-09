# frozen_string_literal: true

require "yaml"

module Temples
  class Manifest
    MANIFEST_PATH = File.expand_path("manifest.yml", __dir__)

    class << self
      def all
        @all ||= load_data.fetch("temples")
      end

      def slugs
        all.map { |entry| entry.fetch("slug") }
      end

      def find(slug)
        all.find { |entry| entry["slug"] == slug.to_s } || {}
      end

      def deploy_path(slug, key)
        fetch_nested(find(slug), ["deploy", key])
      end

      def expo_value(slug, key)
        fetch_nested(find(slug), ["expo", key])
      end
    end

    def self.load_data
      YAML.safe_load_file(MANIFEST_PATH)
    end
    private_class_method :load_data

    def self.fetch_nested(hash, path)
      path.reduce(hash) do |value, key|
        value.is_a?(Hash) ? value[key] : nil
      end
    end
    private_class_method :fetch_nested
  end
end
