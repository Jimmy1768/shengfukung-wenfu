require "test_helper"

class TempleOfferingSetupDraftTest < ActiveSupport::TestCase
  test "generates YAML-shaped template output from setup payload" do
    temple = create_temple
    draft = temple.temple_offering_setup_drafts.create!(
      offering_kind: "service",
      slug: "ancestor-light",
      label: "Ancestor Light",
      registration_period_key: "perennial",
      price_cents: 60_000,
      currency: "TWD",
      setup_payload: {
        "category" => "lamp",
        "field_requirements" => %w[ancestor_name blessing_name],
        "options" => [{ "label" => "One year", "value" => "year" }],
        "operational_notes" => "Confirm name plate before printing."
      }
    )

    template = draft.generated_template
    assert_equal "ancestor-light", template["slug"]
    assert_equal "service", template["kind"]
    assert_equal "Ancestor Light", template["label"]
    assert_equal "perennial", template["registration_period_key"]
    assert_equal 60_000, template.dig("attributes", "price_cents")
    assert_equal "lamp", template.dig("defaults", "offering_type")
    assert_equal %w[ancestor_name blessing_name], template["form_fields"]
    assert_includes draft.generated_template_yaml, "ancestor-light"
  end

  test "status transitions record review and apply admins without creating live offerings" do
    temple = create_temple
    admin = create_admin_user(temple: temple, role: "owner")
    draft = temple.temple_offering_setup_drafts.create!(
      offering_kind: "service",
      slug: "peace-light",
      label: "Peace Light",
      price_cents: 100_000,
      currency: "TWD"
    )

    assert_no_difference -> { temple.temple_services.count } do
      draft.submit!(admin)
      draft.review!(admin, notes: "Ready")
      draft.apply!(admin)
    end

    assert_equal "applied", draft.status
    assert_equal admin.admin_account, draft.reviewed_by_admin
    assert_equal admin.admin_account, draft.applied_by_admin
    assert draft.submitted_at.present?
    assert draft.reviewed_at.present?
    assert draft.applied_at.present?
  end
end
