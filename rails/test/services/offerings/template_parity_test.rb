# frozen_string_literal: true

require "test_helper"

module Offerings
  class TemplateParityTest < ActiveSupport::TestCase
    test "loader configuration contains only the approved TWD 50 services" do
      loader = TemplateLoader.new("shengfukung-demo")
      services = loader.services
      expected_slugs = %w[ghost-festival-table incense-oil lamp-service liberation-ritual]

      assert_empty loader.events
      assert_equal expected_slugs, services.map { |service| service.fetch(:slug) }.sort
      assert_equal expected_slugs.length, services.length

      services.each do |service|
        assert_equal "TWD", service.dig(:attributes, :currency)
        assert_equal 5000, service.dig(:attributes, :price_cents)
        assert_equal "NT$50", Currency::Symbols.format_amount(service.dig(:attributes, :price_cents), service.dig(:attributes, :currency))
      end
    end

    test "report identifies the approved catalog and preserves inferred rows as orphaned" do
      temple = shengfukung_temple

      inferred_service = temple.temple_services.create!(
        slug: "peace-opera-household",
        title: "Historical inferred service",
        currency: "TWD",
        price_cents: 1500,
        status: "draft",
        metadata: { "historical" => "preserve" }
      )

      result = TemplateParity.report(temple)

      assert_includes result.missing_services, "incense-oil"
      refute_includes result.missing_services, "peace-opera-household"
      refute_includes result.missing_services, "ritual-bucket-ceremony"
      assert_includes result.orphaned_services, "peace-opera-household"
      assert_empty result.missing_events

      result = TemplateParity.ensure_missing!(temple, kinds: [:services])

      assert_equal %w[ghost-festival-table incense-oil lamp-service liberation-ritual], result.created_services.sort
      assert_equal 5, temple.temple_services.count
      assert_equal 1500, inferred_service.reload.price_cents
      assert_equal "draft", inferred_service.status
      assert_equal({ "historical" => "preserve" }, inferred_service.metadata)
    end

    test "ensure_missing! creates exactly the approved TWD 50 draft services from yaml templates" do
      temple = shengfukung_temple

      result = TemplateParity.ensure_missing!(temple, kinds: [:services])

      expected_slugs = %w[ghost-festival-table incense-oil lamp-service liberation-ritual]
      assert_equal expected_slugs, result.created_services.sort
      assert_equal expected_slugs, temple.temple_services.order(:slug).pluck(:slug)

      temple.temple_services.order(:slug).each do |service|
        assert_equal "TWD", service.currency
        assert_equal 5000, service.price_cents
        assert_equal "NT$50", Currency::Symbols.format_amount(service.price_cents, service.currency)
        assert_equal "draft", service.status
        assert_equal "https://maps.example.test/temple", service.default_location
      end

      lamp_service = temple.temple_services.find_by!(slug: "lamp-service")
      assert_equal "2026-lantern", lamp_service.registration_period_key
      assert_equal "2026 點燈檔期", lamp_service.period_label
      assert_equal "lamp", lamp_service.metadata["offering_type"]
      assert_equal "點燈作業", lamp_service.metadata["form_label"]
      assert lamp_service.metadata["form_options"]["lamp_type"].any?
    end

    private

    def shengfukung_temple
      create_temple(
        slug: "shengfukung-demo",
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
    end
  end
end
