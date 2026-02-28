# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "yaml"

module Registrations
  class PeriodKeyRolloverTest < ActiveSupport::TestCase
    test "dry-run rolls year-prefixed period keys and labels without writing files" do
      Dir.mktmpdir do |dir|
        temple = create_temple(slug: "rollover-dry")
        path = File.join(dir, "#{temple.slug}.yml")
        original = {
          "slug" => temple.slug,
          "registration_periods" => [
            { "key" => "2026-ghost-month", "label_zh" => "2026 中元", "label_en" => "Ghost Month 2026" },
            { "key" => "perennial", "label_zh" => "常年", "label_en" => "Perennial" }
          ]
        }
        File.write(path, YAML.dump(original))

        result = PeriodKeyRollover.call(slug: temple.slug, write: false, config_dir: dir)
        entry = result.fetch(:results).first

        assert_equal 1, entry[:updated_keys].size
        assert_equal "2027-ghost-month", entry[:updated_keys]["2026-ghost-month"]
        assert_includes entry[:skipped_keys], "perennial"
        assert_equal false, entry[:wrote_file]

        persisted = YAML.safe_load(File.read(path), permitted_classes: [Date, Time], aliases: true)
        assert_equal "2026-ghost-month", persisted["registration_periods"].first["key"]
      end
    end

    test "write mode updates yaml and optionally updates existing services" do
      Dir.mktmpdir do |dir|
        temple = create_temple(slug: "rollover-write")
        path = File.join(dir, "#{temple.slug}.yml")
        File.write(
          path,
          YAML.dump(
            {
              "slug" => temple.slug,
              "registration_periods" => [
                { "key" => "2026-lantern", "label_zh" => "2026 點燈檔期", "label_en" => "Lantern Cycle 2026" }
              ]
            }
          )
        )
        temple.update_columns(
          metadata: {
            "registration_periods" => [
              { "key" => "2026-lantern", "label_zh" => "2026 點燈檔期", "label_en" => "Lantern Cycle 2026" }
            ]
          }
        )

        service = TempleService.create!(
          temple: temple,
          slug: "service-#{SecureRandom.hex(2)}",
          title: "Service",
          currency: "TWD",
          price_cents: 1000,
          registration_period_key: "2026-lantern",
          period_label: "2026 點燈檔期"
        )

        result = PeriodKeyRollover.call(slug: temple.slug, write: true, update_services: true, config_dir: dir)
        entry = result.fetch(:results).first

        assert_equal true, entry[:wrote_file]
        assert_equal 1, entry[:service_updates]
        assert_equal "2027-lantern", service.reload.registration_period_key
        assert_equal "2027 點燈檔期", service.period_label

        persisted = YAML.safe_load(File.read(path), permitted_classes: [Date, Time], aliases: true)
        assert_equal "2027-lantern", persisted["registration_periods"].first["key"]
      end
    end

    test "reports duplicate key collisions after rollover" do
      Dir.mktmpdir do |dir|
        temple = create_temple(slug: "rollover-collision")
        path = File.join(dir, "#{temple.slug}.yml")
        File.write(
          path,
          YAML.dump(
            {
              "slug" => temple.slug,
              "registration_periods" => [
                { "key" => "2026-lantern", "label_zh" => "2026 點燈", "label_en" => "Lantern 2026" },
                { "key" => "2026-lantern", "label_zh" => "2026 點燈 B", "label_en" => "Lantern 2026 B" }
              ]
            }
          )
        )

        result = PeriodKeyRollover.call(slug: temple.slug, write: false, config_dir: dir)
        entry = result.fetch(:results).first

        assert entry[:errors].any?
        assert_includes entry[:errors].first, "duplicate_period_keys_after_rollover"
      end
    end
  end
end
