# frozen_string_literal: true

require "test_helper"

module Offerings
  class TemplateParityTest < ActiveSupport::TestCase
    test "report identifies missing and orphaned records by kind" do
      temple = create_temple(slug: "shengfukung-wenfu")

      temple.temple_services.create!(
        slug: "custom-service",
        title: "Custom Service",
        currency: "TWD",
        price_cents: 1000
      )

      result = TemplateParity.report(temple)

      assert_includes result.missing_services, "incense-donation"
      assert_includes result.missing_services, "ritual-bucket-ceremony"
      assert_includes result.orphaned_services, "custom-service"
      assert_empty result.missing_events
    end

    test "ensure_missing! creates missing services from yaml templates" do
      temple = create_temple(
        slug: "shengfukung-wenfu",
        metadata: {
          "registration_periods" => [
            { "key" => "perennial", "label_zh" => "常年供燈", "label_en" => "Perennial" },
            { "key" => "2026-lantern", "label_zh" => "2026 點燈檔期", "label_en" => "Lantern Cycle 2026" },
            { "key" => "2026-ghost-month", "label_zh" => "2026 中元普渡", "label_en" => "Ghost Month 2026" }
          ]
        },
        contact_info: {
          "mapUrl" => "https://maps.example.test/temple"
        }
      )

      result = TemplateParity.ensure_missing!(temple, kinds: [:services])

      assert_includes result.created_services, "ritual-bucket-ceremony"

      service = temple.temple_services.find_by!(slug: "ritual-bucket-ceremony")
      assert_equal "禮斗法會", service.title
      assert_equal "perennial", service.registration_period_key
      assert_equal "常年供燈", service.period_label
      assert_equal "draft", service.status
      assert_equal "https://maps.example.test/temple", service.default_location
      assert_equal "ritual", service.metadata["offering_type"]
      assert_equal "禮斗法會", service.metadata["form_label"]
      assert service.metadata["form_options"]["blessing_target_type"].any?
    end
  end
end
