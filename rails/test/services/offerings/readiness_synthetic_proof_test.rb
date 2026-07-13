# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db", "seeds", "temples").to_s
require "open3"

module Offerings
  class ReadinessSyntheticProofTest < ActiveSupport::TestCase
    test "bootstrap and ensure_missing create synthetic draft service from durable yaml" do
      assert_difference("Temple.count", 1) do
        Seeds::Temples.bootstrap(slug: "readiness-synthetic")
      end

      temple = Temple.find_by!(slug: "readiness-synthetic")
      result = TemplateParity.ensure_missing!(temple, kinds: [:services])

      assert_equal ["readiness-peace-lamp"], result.created_services

      service = temple.temple_services.find_by!(slug: "readiness-peace-lamp")
      assert_equal "平安祈福燈", service.title
      assert_equal "draft", service.status
      assert_equal 1200, service.price_cents
      assert_equal "2026-q4-peace-light", service.registration_period_key
      assert_equal "2026 第四季平安祈福", service.period_label
      assert_equal "lamp", service.metadata["offering_type"]
      assert_equal "平安祈福燈", service.metadata["form_label"]
      assert_equal %w[lamp_type lamp_location fulfillment_method certificate_hint logistics_notes], service.metadata.dig("form_fields", "lamp_details", "fields")
      assert_equal ["平安燈", "光明燈", "闔家燈"], service.metadata.dig("form_options", "lamp_type")
      assert_equal %w[preferred_date preferred_slot], service.metadata.dig("registration_form", "sections", "logistics", "fields")
      assert_equal ["上午", "下午", "晚上"], service.metadata.dig("registration_form", "field_settings", "preferred_slot", "options")
      assert_equal true, service.metadata["allow_repeat_registrations"]
    end

    test "synthetic ensure rerun is idempotent and sync restores metadata without duplicates" do
      Seeds::Temples.bootstrap(slug: "readiness-synthetic")
      temple = Temple.find_by!(slug: "readiness-synthetic")
      first = TemplateParity.ensure_missing!(temple, kinds: [:services])

      assert_equal ["readiness-peace-lamp"], first.created_services

      service = temple.temple_services.find_by!(slug: "readiness-peace-lamp")
      service.update!(
        metadata: service.metadata.merge(
          "form_label" => "Stale Label",
          "form_options" => { "lamp_type" => ["舊選項"] }
        )
      )

      assert_no_difference -> { temple.temple_services.count } do
        second = TemplateParity.ensure_missing!(temple, kinds: [:services])
        assert_empty second.created_services
      end

      sync = TemplateSync.call(temple)
      assert_equal ["readiness-peace-lamp"], sync.updated_services

      service.reload
      assert_equal "平安祈福燈", service.metadata["form_label"]
      assert_equal ["平安燈", "光明燈", "闔家燈"], service.metadata.dig("form_options", "lamp_type")
    end

    test "selected slug helpers fail closed for unknown temples" do
      repo = Rails.root.parent.to_s

      audit_stdout, audit_stderr, audit_status = Open3.capture3(
        { "SLUG" => "definitely-missing-readiness-slug" },
        "ruby",
        "ops/scripts/audit_offering_configs.rb",
        chdir: repo
      )
      sync_stdout, sync_stderr, sync_status = Open3.capture3(
        { "SLUG" => "definitely-missing-readiness-slug" },
        "ruby",
        "ops/scripts/sync_offering_configs.rb",
        chdir: repo
      )

      refute audit_status.success?
      refute sync_status.success?
      assert_equal "", audit_stdout
      assert_equal "", sync_stdout
      assert_includes audit_stderr, "Unknown SLUG: definitely-missing-readiness-slug"
      assert_includes sync_stderr, "Unknown SLUG: definitely-missing-readiness-slug"
    end
  end
end
