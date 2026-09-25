# frozen_string_literal: true

require "test_helper"
require "rake"

class OfferingsRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("offerings:apply_templates")
    Rake::Task["offerings:apply_templates"].reenable
  end

  test "creates all 4 real offering templates as published, and is idempotent on re-run" do
    temple = create_temple(slug: "shengfukung-demo", metadata: {
      "registration_periods" => [
        { "key" => "perennial", "label_zh" => "常年供燈", "label_en" => "Perennial" },
        { "key" => "2026-lantern", "label_zh" => "2026 點燈", "label_en" => "2026 Lantern" },
        { "key" => "2026-ghost-month", "label_zh" => "2026 中元", "label_en" => "2026 Ghost Month" }
      ]
    })

    Rake::Task["offerings:apply_templates"].invoke(temple.slug)

    slugs = %w[incense-donation lamp-service ghost-festival-table liberation-ritual]
    assert_equal slugs.sort, temple.temple_services.reload.pluck(:slug).sort
    temple.temple_services.each do |service|
      assert_equal "published", service.status
      assert service.metadata["registration_form"].present?, "#{service.slug} should have synced registration_form metadata"
    end
    assert_equal 1, SystemAuditLog.where(action: "offerings.templates_applied", temple:).count

    Rake::Task["offerings:apply_templates"].reenable
    Rake::Task["offerings:apply_templates"].invoke(temple.slug)

    assert_equal 4, temple.temple_services.reload.count, "re-running must not create duplicates"
  end
end
