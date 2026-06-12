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

  test "edit preserves option lists longer than three rows" do
    draft = @temple.temple_offering_setup_drafts.create!(
      offering_kind: "service",
      slug: "many-options",
      label: "Many Options",
      price_cents: 60_000,
      currency: "TWD",
      setup_payload: {
        "field_requirements" => %w[lamp_type],
        "options" => [
          { "field" => "lamp_type", "label" => "光明燈", "value" => "bright" },
          { "field" => "lamp_type", "label" => "文昌燈", "value" => "study" },
          { "field" => "lamp_type", "label" => "財神燈", "value" => "wealth" },
          { "field" => "lamp_type", "label" => "太歲燈", "value" => "taisui" }
        ]
      }
    )
    sign_in_admin(@admin)

    get edit_admin_offering_setup_draft_path(draft)
    assert_response :success
    assert_includes response.body, "太歲燈"

    patch admin_offering_setup_draft_path(draft), params: {
      temple_offering_setup_draft: {
        offering_kind: "service",
        label: "Many Options",
        slug: "many-options",
        category: "lamp",
        price_cents: "600",
        currency: "TWD",
        field_requirements: %w[lamp_type],
        options: {
          "0" => { field: "lamp_type", label: "光明燈", value: "bright" },
          "1" => { field: "lamp_type", label: "文昌燈", value: "study" },
          "2" => { field: "lamp_type", label: "財神燈", value: "wealth" },
          "3" => { field: "lamp_type", label: "太歲燈", value: "taisui" }
        },
        options_text: "malformed",
        operational_notes: ""
      }
    }

    assert_redirected_to admin_offering_setup_draft_path(draft)
    assert_equal 4, draft.reload.setup_payload["options"].size
    assert_equal "taisui", draft.setup_payload.dig("options", 3, "value")
  end

  test "edit preserves unsupported legacy option targets as visible blockers" do
    draft = @temple.temple_offering_setup_drafts.create!(
      offering_kind: "service",
      slug: "legacy-option",
      label: "Legacy Option",
      price_cents: 60_000,
      currency: "TWD",
      setup_payload: {
        "field_requirements" => %w[logistics_notes],
        "options" => [
          { "field" => "legacy_option_field", "label" => "Legacy", "value" => "legacy" }
        ]
      }
    )
    sign_in_admin(@admin)

    get edit_admin_offering_setup_draft_path(draft)
    assert_response :success
    assert_includes response.body, "legacy_option_field"
    assert_includes response.body, "Legacy"

    patch admin_offering_setup_draft_path(draft), params: {
      temple_offering_setup_draft: {
        offering_kind: "service",
        label: "Legacy Option",
        slug: "legacy-option",
        category: "service",
        price_cents: "600",
        currency: "TWD",
        field_requirements: %w[logistics_notes],
        options: {
          "0" => { field: "legacy_option_field", label: "Legacy", value: "legacy" }
        },
        operational_notes: ""
      }
    }

    assert_redirected_to admin_offering_setup_draft_path(draft)
    assert_equal "legacy_option_field", draft.reload.setup_payload.dig("options", 0, "field")

    draft.submit!(@admin)
    draft.review!(@admin, notes: "Ready")
    post apply_admin_offering_setup_draft_path(draft)
    assert_response :unprocessable_content
    assert_includes response.body, "legacy_option_field"
    assert_equal "reviewed", draft.reload.status
  end

  test "create and update persist selected registration intake fields" do
    sign_in_admin(@admin)

    post admin_offering_setup_drafts_path, params: {
      temple_offering_setup_draft: {
        offering_kind: "service",
        label: "Ancestor Blessing",
        slug: "ancestor-blessing",
        category: "ritual",
        registration_period_key: "perennial",
        price_cents: "1200",
        currency: "TWD",
        field_requirements: %w[blessing_target_type blessing_names],
        registration_fields: {
          order: %w[quantity unit_price_cents currency certificate_number],
          contact: %w[primary_contact phone],
          logistics: %w[preferred_date preferred_slot],
          ritual_metadata: %w[ancestor_placard_name dedication_message]
        }
      }
    }

    draft = @temple.temple_offering_setup_drafts.find_by!(slug: "ancestor-blessing")
    assert_redirected_to admin_offering_setup_draft_path(draft)
    assert_equal %w[quantity unit_price_cents currency certificate_number], draft.setup_payload.dig("registration_fields", "order")
    assert_equal %w[ancestor_placard_name dedication_message], draft.setup_payload.dig("registration_fields", "ritual_metadata")

    get edit_admin_offering_setup_draft_path(draft)
    assert_response :success
    assert_includes response.body, "祖先牌位姓名"

    patch admin_offering_setup_draft_path(draft), params: {
      temple_offering_setup_draft: {
        offering_kind: "service",
        label: "Ancestor Blessing",
        slug: "ancestor-blessing",
        category: "ritual",
        registration_period_key: "perennial",
        price_cents: "1200",
        currency: "TWD",
        field_requirements: %w[blessing_target_type blessing_names],
        registration_fields: {
          order: %w[quantity unit_price_cents currency],
          contact: %w[primary_contact phone email],
          logistics: [],
          ritual_metadata: %w[ancestor_placard_name certificate_notes]
        }
      }
    }

    assert_redirected_to admin_offering_setup_draft_path(draft)
    assert_equal %w[primary_contact phone email], draft.reload.setup_payload.dig("registration_fields", "contact")
    assert_equal [], draft.setup_payload.dig("registration_fields", "logistics")
    assert_equal %w[ancestor_placard_name certificate_notes], draft.setup_payload.dig("registration_fields", "ritual_metadata")
  end

  test "admin setup rehearsal applies realistic service examples as draft offerings" do
    sign_in_admin(@admin)
    examples = [
      {
        label: "光明燈服務",
        slug: "bright-lamp-service",
        category: "lamp",
        price: "600",
        fields: %w[lamp_type lamp_location fulfillment_method logistics_notes],
        options: [
          option_entry("lamp_type", "光明燈", "bright_light"),
          option_entry("lamp_type", "文昌燈", "study_lamp"),
          option_entry("lamp_type", "財神燈", "wealth_lamp"),
          option_entry("lamp_type", "太歲燈", "taisui_lamp"),
          option_entry("fulfillment_method", "廟方代辦", "temple_handles")
        ],
        expected_options: {
          "lamp_type" => %w[bright_light study_lamp wealth_lamp taisui_lamp],
          "fulfillment_method" => %w[temple_handles]
        },
        registration_fields: {
          "order" => %w[quantity unit_price_cents currency certificate_number],
          "contact" => %w[primary_contact phone email],
          "logistics" => %w[preferred_slot],
          "ritual_metadata" => []
        }
      },
      {
        label: "祈福斗燈",
        slug: "blessing-dou-lamp",
        category: "ritual",
        price: "1200",
        fields: %w[blessing_target_type blessing_names certificate_hint fulfillment_method],
        options: [
          option_entry("blessing_target_type", "總斗主", "main_dou"),
          option_entry("blessing_target_type", "福德正神斗", "earth_god_dou"),
          option_entry("blessing_target_type", "七星斗", "seven_star_dou"),
          option_entry("blessing_target_type", "五路財神斗", "wealth_dou"),
          option_entry("fulfillment_method", "現場確認", "onsite_confirm")
        ],
        expected_options: {
          "blessing_target_type" => %w[main_dou earth_god_dou seven_star_dou wealth_dou],
          "fulfillment_method" => %w[onsite_confirm]
        },
        registration_fields: {
          "order" => %w[quantity unit_price_cents currency certificate_number],
          "contact" => %w[primary_contact phone],
          "logistics" => %w[preferred_date preferred_slot],
          "ritual_metadata" => %w[ancestor_placard_name dedication_message certificate_notes]
        }
      },
      {
        label: "供桌服務",
        slug: "offering-table-service",
        category: "table",
        price: "2000",
        fields: %w[table_size table_items logistics_notes fulfillment_method],
        options: [
          option_entry("table_size", "小供桌", "small_table"),
          option_entry("table_size", "中供桌", "medium_table"),
          option_entry("table_size", "大供桌", "large_table"),
          option_entry("fulfillment_method", "親至現場確認", "onsite")
        ],
        expected_options: {
          "table_size" => %w[small_table medium_table large_table],
          "fulfillment_method" => %w[onsite]
        },
        registration_fields: {
          "order" => %w[quantity unit_price_cents currency],
          "contact" => %w[primary_contact phone email notes],
          "logistics" => %w[preferred_date preferred_slot ceremony_location],
          "ritual_metadata" => []
        }
      }
    ]

    examples.each do |example|
      assert_difference -> { @temple.temple_offering_setup_drafts.count }, 1 do
        post admin_offering_setup_drafts_path, params: {
          temple_offering_setup_draft: draft_params_for(example)
        }
      end

      draft = @temple.temple_offering_setup_drafts.find_by!(slug: example[:slug])
      assert_redirected_to admin_offering_setup_draft_path(draft)
      assert_equal "draft", draft.status
      assert_equal example[:fields], draft.setup_payload["field_requirements"]
      assert_equal example[:options].size, draft.setup_payload["options"].size
      assert_equal example[:registration_fields], draft.setup_payload["registration_fields"]

      get edit_admin_offering_setup_draft_path(draft)
      assert_response :success
      example[:options].each do |option|
        assert_includes response.body, option.fetch(:label)
      end

      post submit_admin_offering_setup_draft_path(draft)
      assert_redirected_to admin_offering_setup_draft_path(draft)
      assert_equal "submitted", draft.reload.status

      post review_admin_offering_setup_draft_path(draft), params: {
        temple_offering_setup_draft: { review_notes: "Local rehearsal approved." }
      }
      assert_redirected_to admin_offering_setup_draft_path(draft)
      assert_equal "reviewed", draft.reload.status

      patch admin_offering_setup_draft_path(draft), params: {
        temple_offering_setup_draft: draft_params_for(example).merge(label: "Changed after review")
      }
      assert_redirected_to admin_offering_setup_draft_path(draft)
      assert_equal example[:label], draft.reload.label

      assert_difference -> { @temple.temple_services.count }, 1 do
        post apply_admin_offering_setup_draft_path(draft)
      end
      assert_redirected_to admin_offering_setup_draft_path(draft)
      assert_equal "applied", draft.reload.status

      service = draft.applied_offering
      assert_equal "draft", service.status
      assert_equal example[:label], service.title
      assert_equal example[:category], service.metadata["offering_type"]
      assert_equal example[:fields], service.metadata.dig("form_fields", "setup", "fields")
      assert_equal example[:expected_options], service.metadata["form_options"].slice(*example[:expected_options].keys)
      assert_equal expected_registration_sections(example[:registration_fields]), service.metadata.dig("registration_form", "sections")
      assert_equal "admin_offering_setup_draft", service.metadata.dig("form_ui", "generated_from")
      assert_equal({ "quantity" => 1 }, service.metadata.dig("registration_form", "defaults", "order"))
    end
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

  private

  def option_entry(field, label, value)
    { field:, label:, value: }
  end

  def draft_params_for(example)
    {
      offering_kind: "service",
      label: example.fetch(:label),
      slug: example.fetch(:slug),
      category: example.fetch(:category),
      registration_period_key: "perennial",
      price_cents: example.fetch(:price),
      currency: "TWD",
      field_requirements: example.fetch(:fields),
      registration_fields: example.fetch(:registration_fields),
      options: options_params_for(example.fetch(:options)),
      operational_notes: "Local admin setup rehearsal."
    }
  end

  def options_params_for(options)
    options.each_with_index.to_h do |option, index|
      [index.to_s, option]
    end
  end

  def expected_registration_sections(registration_fields)
    registration_fields.transform_values do |fields|
      fields.any? ? { "fields" => fields } : false
    end
  end
end
