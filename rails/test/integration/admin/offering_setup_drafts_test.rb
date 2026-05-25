require "test_helper"

class AdminOfferingSetupDraftsTest < ActionDispatch::IntegrationTest
  setup do
    @temple = create_temple(
      metadata: {
        "registration_periods" => [
          { "key" => "perennial", "label_zh" => "全年", "label_en" => "Year-round" }
        ]
      }
    )
    @admin = create_admin_user(temple: @temple, role: "admin", permission_overrides: { manage_offerings: true })
  end

  test "manager can create edit submit review and apply setup draft without mutating live offerings" do
    sign_in_admin(@admin)

    get admin_offerings_path
    assert_response :success
    assert_includes response.body, admin_offering_setup_drafts_path

    assert_difference -> { @temple.temple_offering_setup_drafts.count }, 1 do
      post admin_offering_setup_drafts_path, params: {
        temple_offering_setup_draft: {
          offering_kind: "service",
          label: "Peace Light",
          slug: "peace-light",
          category: "lamp",
          registration_period_key: "perennial",
          price_cents: "600",
          currency: "TWD",
          field_requirements: %w[fulfillment_method logistics_notes],
          options: {
            "0" => {
              field: "fulfillment_method",
              label: "One year",
              value: "year"
            }
          },
          operational_notes: "Confirm name plate."
        }
      }
    end

    draft = @temple.temple_offering_setup_drafts.order(created_at: :desc).first
    assert_redirected_to admin_offering_setup_draft_path(draft)
    assert_equal "draft", draft.status
    assert_equal 60_000, draft.price_cents
    assert_equal %w[fulfillment_method logistics_notes], draft.setup_payload["field_requirements"]
    assert_equal "year", draft.setup_payload.dig("options", 0, "value")

    patch admin_offering_setup_draft_path(draft), params: {
      temple_offering_setup_draft: {
        offering_kind: "service",
        label: "Peace Light Deluxe",
        slug: "peace-light-deluxe",
        category: "lamp",
        registration_period_key: "perennial",
        price_cents: "800",
        currency: "TWD",
        field_requirements_text: "fulfillment_method",
        options_text: "",
        operational_notes: "Updated notes."
      }
    }

    assert_redirected_to admin_offering_setup_draft_path(draft)
    assert_equal "Peace Light Deluxe", draft.reload.label
    assert_equal 80_000, draft.price_cents

    assert_difference -> { SystemAuditLog.where(action: "admin.offering_setup_drafts.submit").count }, 1 do
      post submit_admin_offering_setup_draft_path(draft)
    end
    assert_equal "submitted", draft.reload.status

    post review_admin_offering_setup_draft_path(draft), params: {
      temple_offering_setup_draft: { review_notes: "Ready to apply." }
    }
    assert_equal "reviewed", draft.reload.status
    assert_equal "Ready to apply.", draft.review_notes

    get edit_admin_offering_setup_draft_path(draft)
    assert_redirected_to admin_offering_setup_draft_path(draft)

    patch admin_offering_setup_draft_path(draft), params: {
      temple_offering_setup_draft: {
        offering_kind: "service",
        label: "Changed After Review",
        slug: "changed-after-review",
        category: "lamp",
        registration_period_key: "perennial",
        price_cents: "900",
        currency: "TWD",
        field_requirements_text: "registrant_name",
        options_text: "",
        operational_notes: "Stale change."
      }
    }
    assert_redirected_to admin_offering_setup_draft_path(draft)
    assert_equal "Peace Light Deluxe", draft.reload.label
    assert_equal "reviewed", draft.status

    assert_difference -> { @temple.temple_services.count }, 1 do
      post apply_admin_offering_setup_draft_path(draft)
    end
    assert_equal "applied", draft.reload.status
    assert_equal "TempleService", draft.applied_offering_type
    assert_equal "draft", draft.applied_offering.status
  end

  test "edit form displays supported catalog fields and unsupported legacy fields" do
    draft = @temple.temple_offering_setup_drafts.create!(
      offering_kind: "service",
      slug: "legacy",
      label: "Legacy",
      price_cents: 60_000,
      currency: "TWD",
      setup_payload: {
        "field_requirements" => %w[fulfillment_method unsupported_legacy_field],
        "options" => [{ "field" => "fulfillment_method", "label" => "Temple handles", "value" => "temple" }]
      }
    )
    sign_in_admin(@admin)

    get edit_admin_offering_setup_draft_path(draft)

    assert_response :success
    assert_includes response.body, "fulfillment_method"
    assert_includes response.body, "unsupported_legacy_field"
    assert_includes response.body, "Temple handles"
  end

  test "admin without manage offerings cannot access setup drafts" do
    restricted = create_admin_user(temple: @temple, role: "admin")
    sign_in_admin(restricted)

    get admin_offering_setup_drafts_path

    assert_redirected_to admin_dashboard_path
  end

  test "apply shows validation errors without creating offering" do
    draft = @temple.temple_offering_setup_drafts.create!(
      offering_kind: "service",
      slug: "unsupported",
      label: "Unsupported",
      price_cents: 60_000,
      currency: "TWD",
      setup_payload: { "field_requirements" => %w[unsupported_field] }
    )
    draft.submit!(@admin)
    draft.review!(@admin, notes: "Ready")
    sign_in_admin(@admin)

    assert_no_difference -> { @temple.temple_services.count } do
      post apply_admin_offering_setup_draft_path(draft)
    end

    assert_response :unprocessable_content
    assert_includes response.body, "unsupported_field"
    assert_equal "reviewed", draft.reload.status
  end
end
