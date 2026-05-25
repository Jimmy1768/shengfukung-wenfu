require "test_helper"

module Offerings
  class SetupDraftApplierTest < ActiveSupport::TestCase
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

    test "applies a reviewed service setup draft to a draft service with template metadata" do
      draft = reviewed_draft(
        slug: "peace-light",
        label: "Peace Light",
        setup_payload: {
          "category" => "lamp",
          "field_requirements" => %w[fulfillment_method logistics_notes],
          "options" => [{ "field" => "fulfillment_method", "label" => "Temple handles", "value" => "temple" }],
          "operational_notes" => "Confirm name plate."
        }
      )

      assert_difference -> { @temple.temple_services.count }, 1 do
        result = Offerings::SetupDraftApplier.call(draft: draft, admin: @admin)
        assert result.success?, result.errors.inspect
      end

      service = @temple.temple_services.order(created_at: :desc).first
      assert_equal "draft", service.status
      assert_equal "peace-light", service.slug
      assert_equal "Peace Light", service.title
      assert_equal 60_000, service.price_cents
      assert_equal "perennial", service.registration_period_key
      assert_equal "全年", service.period_label
      assert_equal "lamp", service.metadata["offering_type"]
      assert_equal "Peace Light", service.metadata["form_label"]
      assert_equal %w[fulfillment_method logistics_notes], service.metadata.dig("form_fields", "setup", "fields")
      assert_equal ["temple"], service.metadata.dig("form_options", "fulfillment_method")
      assert_equal %w[quantity unit_price_cents currency], service.metadata.dig("registration_form", "sections", "order", "fields")
      assert_equal true, service.metadata["allow_repeat_registrations"]

      draft.reload
      assert_equal "applied", draft.status
      assert_equal service, draft.applied_offering
    end

    test "reapplying an already applied draft does not create duplicates" do
      draft = reviewed_draft(
        slug: "incense",
        label: "Incense",
        setup_payload: { "field_requirements" => %w[fulfillment_method] }
      )
      first = Offerings::SetupDraftApplier.call(draft: draft, admin: @admin)
      assert first.success?, first.errors.inspect

      assert_no_difference -> { @temple.temple_services.count } do
        second = Offerings::SetupDraftApplier.call(draft: draft.reload, admin: @admin)
        assert second.success?, second.errors.inspect
        assert_equal first.target, second.target
      end
    end

    test "unsupported fields block apply without creating service" do
      draft = reviewed_draft(
        slug: "bad-field",
        label: "Bad Field",
        setup_payload: { "field_requirements" => %w[unknown_runtime_field] }
      )

      assert_no_difference -> { @temple.temple_services.count } do
        result = Offerings::SetupDraftApplier.call(draft: draft, admin: @admin)
        refute result.success?
        assert_includes result.errors.join, "unknown_runtime_field"
      end
      assert_equal "reviewed", draft.reload.status
      assert_nil draft.applied_offering
    end

    test "unsupported option fields block apply without creating service" do
      draft = reviewed_draft(
        slug: "bad-option",
        label: "Bad Option",
        setup_payload: {
          "field_requirements" => %w[logistics_notes],
          "options" => [{ "field" => "logistics_notes", "label" => "Option", "value" => "option" }]
        }
      )

      assert_no_difference -> { @temple.temple_services.count } do
        result = Offerings::SetupDraftApplier.call(draft: draft, admin: @admin)
        refute result.success?
        assert_includes result.errors.join, "logistics_notes"
      end
    end

    test "unrelated slug collision blocks apply" do
      @temple.temple_services.create!(
        slug: "existing",
        title: "Existing",
        currency: "TWD",
        price_cents: 100,
        status: "draft"
      )
      draft = reviewed_draft(
        slug: "existing",
        label: "Existing Setup",
        setup_payload: { "field_requirements" => %w[fulfillment_method] }
      )

      assert_no_difference -> { @temple.temple_services.count } do
        result = Offerings::SetupDraftApplier.call(draft: draft, admin: @admin)
        refute result.success?
        assert_includes result.errors.join, "existing"
      end
    end

    test "event apply is blocked until scheduling fields are supported" do
      draft = reviewed_draft(
        offering_kind: "event",
        slug: "event-setup",
        label: "Event Setup",
        setup_payload: { "field_requirements" => %w[fulfillment_method] }
      )

      assert_no_difference -> { @temple.temple_events.count } do
        result = Offerings::SetupDraftApplier.call(draft: draft, admin: @admin)
        refute result.success?
        assert result.errors.any?
      end
    end

    private

    def reviewed_draft(offering_kind: "service", slug:, label:, setup_payload:)
      draft = @temple.temple_offering_setup_drafts.create!(
        offering_kind: offering_kind,
        slug: slug,
        label: label,
        registration_period_key: "perennial",
        price_cents: 60_000,
        currency: "TWD",
        setup_payload: setup_payload
      )
      draft.submit!(@admin)
      draft.review!(@admin, notes: "Ready")
      draft
    end
  end
end
