# frozen_string_literal: true

require "yaml"

module Registrations
  class PeriodKeyRollover
    YEAR_KEY_PATTERN = /\A(\d{4})-(.+)\z/.freeze

    Result = Struct.new(
      :temple_slug,
      :file_path,
      :periods_before,
      :periods_after,
      :updated_keys,
      :skipped_keys,
      :service_updates,
      :wrote_file,
      :errors,
      keyword_init: true
    )

    class << self
      def call(slug: nil, write: false, update_services: false, now: Time.current, config_dir: default_config_dir)
        new(slug:, write:, update_services:, now:, config_dir:).call
      end

      def default_config_dir
        Rails.root.join("db", "temples")
      end
    end

    def initialize(slug:, write:, update_services:, now:, config_dir:)
      @slug = slug
      @write = write
      @update_services = update_services
      @now = now
      @config_dir = Pathname.new(config_dir)
    end

    def call
      results = []

      temples_for_scope.find_each do |temple|
        result = process_temple(temple)
        results << result
        raise ArgumentError, result.errors.join(", ") if result.errors.any? && @write
      end

      {
        write: @write,
        update_services: @update_services,
        temple_count: results.size,
        results: results.map { |entry| serialize(entry) }
      }
    end

    private

    def temples_for_scope
      slugs = @slug.to_s.split(",").map(&:strip).reject(&:blank?)
      scope = slugs.any? ? Temple.where(slug: slugs) : Temple.all
      scope.order(:slug)
    end

    def process_temple(temple)
      file_path = @config_dir.join("#{temple.slug}.yml")
      unless file_path.exist?
        return Result.new(
          temple_slug: temple.slug,
          file_path: file_path.to_s,
          periods_before: [],
          periods_after: [],
          updated_keys: {},
          skipped_keys: [],
          service_updates: 0,
          wrote_file: false,
          errors: ["missing_temple_yaml"]
        )
      end

      yaml_data = YAML.safe_load(File.read(file_path), permitted_classes: [Date, Time], aliases: true) || {}
      periods_before = Array(yaml_data["registration_periods"]).map { |entry| normalize_entry(entry) }

      updated_keys = {}
      skipped_keys = []
      periods_after = periods_before.map do |entry|
        transform_entry(entry, updated_keys:, skipped_keys:)
      end

      duplicates = duplicate_keys(periods_after)
      if duplicates.any?
        return Result.new(
          temple_slug: temple.slug,
          file_path: file_path.to_s,
          periods_before: periods_before,
          periods_after: periods_after,
          updated_keys: updated_keys,
          skipped_keys: skipped_keys,
          service_updates: 0,
          wrote_file: false,
          errors: ["duplicate_period_keys_after_rollover: #{duplicates.join(',')}"]
        )
      end

      wrote_file = false
      service_updates = 0

      if @write
        yaml_data["registration_periods"] = periods_after
        File.write(file_path, YAML.dump(yaml_data))
        wrote_file = true

        if @update_services && updated_keys.any?
          service_updates = update_services_for_temple(temple, updated_keys, periods_after)
        end
      end

      Result.new(
        temple_slug: temple.slug,
        file_path: file_path.to_s,
        periods_before: periods_before,
        periods_after: periods_after,
        updated_keys: updated_keys,
        skipped_keys: skipped_keys,
        service_updates: service_updates,
        wrote_file: wrote_file,
        errors: []
      )
    rescue StandardError => e
      Result.new(
        temple_slug: temple.slug,
        file_path: file_path.to_s,
        periods_before: [],
        periods_after: [],
        updated_keys: {},
        skipped_keys: [],
        service_updates: 0,
        wrote_file: false,
        errors: ["#{e.class}: #{e.message}"]
      )
    end

    def normalize_entry(entry)
      value = entry.respond_to?(:to_h) ? entry.to_h : {}
      value.stringify_keys.slice("key", "label_zh", "label_en")
    end

    def transform_entry(entry, updated_keys:, skipped_keys:)
      key = entry["key"].to_s
      match = YEAR_KEY_PATTERN.match(key)
      return entry.tap { skipped_keys << key if key.present? } unless match

      old_year = match[1]
      suffix = match[2]
      new_year = (old_year.to_i + 1).to_s
      new_key = "#{new_year}-#{suffix}"
      updated_keys[key] = new_key

      {
        "key" => new_key,
        "label_zh" => replace_year_token(entry["label_zh"], old_year, new_year),
        "label_en" => replace_year_token(entry["label_en"], old_year, new_year)
      }.compact
    end

    def replace_year_token(label, old_year, new_year)
      return label if label.blank?

      label.to_s.gsub(/(?<!\d)#{Regexp.escape(old_year)}(?!\d)/, new_year)
    end

    def duplicate_keys(periods)
      periods
        .map { |entry| entry["key"].to_s }
        .reject(&:blank?)
        .tally
        .select { |_key, count| count > 1 }
        .keys
    end

    def update_services_for_temple(temple, updated_keys, rolled_periods)
      labels = rolled_periods.index_by { |entry| entry["key"].to_s }
      updated_count = 0

      TempleService.transaction do
        updated_keys.each do |old_key, new_key|
          label_entry = labels[new_key.to_s] || {}
          next_label = label_entry["label_zh"].presence || label_entry["label_en"].presence || new_key

          temple.temple_services.where(registration_period_key: old_key).find_each do |service|
            service.update_columns(
              registration_period_key: new_key,
              period_label: next_label,
              updated_at: @now
            )
            updated_count += 1
          end
        end
      end

      updated_count
    end

    def serialize(result)
      {
        temple_slug: result.temple_slug,
        file_path: result.file_path,
        periods_before: result.periods_before,
        periods_after: result.periods_after,
        updated_keys: result.updated_keys,
        skipped_keys: result.skipped_keys,
        service_updates: result.service_updates,
        wrote_file: result.wrote_file,
        errors: result.errors
      }
    end
  end
end

