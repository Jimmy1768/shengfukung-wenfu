# frozen_string_literal: true

require "test_helper"

module Registrations
  class ReusePolicyTest < ActiveSupport::TestCase
    setup do
      @temple = create_temple
      @user = User.create!(
        email: "reuse-#{SecureRandom.hex(3)}@example.com",
        english_name: "Reuse Patron",
        encrypted_password: User.password_hash("Password123!")
      )
    end

    def offering_with(field_settings, fields: %w[dedication_message])
      create_offering(temple: @temple, metadata: {
        "registration_form" => {
          "sections" => { "ritual_metadata" => fields, "logistics" => [] },
          "field_settings" => field_settings
        }
      })
    end

    def defaults_for(offering)
      ReusableDefaults.new(user: @user, temple: @temple, offering:)
    end

    test "the runtime default remembers but never prefills an undeclared field" do
      # offer_as_options, not never: only a wrong `prefill` can carry a stale
      # answer into a registration the temple acts on, so the safe default is
      # the one that still preserves rule 3 rather than the one that disables
      # a shipped feature for every un-annotated config.
      offering = offering_with({})
      defaults_for(offering).write!("dedication_message" => "福宴")

      assert_equal %w[福宴], defaults_for(offering).suggestions["dedication_message"]
      assert_empty defaults_for(offering).prefillable, "an undeclared field must never auto-fill"
    end

    test "reuse: never refuses the write even when explicitly declared" do
      offering = offering_with({ "dedication_message" => { "reuse" => "never" } })
      defaults_for(offering).write!("dedication_message" => "福宴")

      assert_empty defaults_for(offering).read
    end

    test "reuse: prefill stores and is offered for prefill, not as a suggestion" do
      offering = offering_with({ "dedication_message" => { "reuse" => "prefill" } })
      service = defaults_for(offering)
      service.write!("dedication_message" => "闔家平安")

      assert_equal "闔家平安", defaults_for(offering).prefillable["dedication_message"]
      assert_empty defaults_for(offering).suggestions
    end

    test "reuse: offer_as_options stores and is offered as a suggestion, never prefilled" do
      offering = offering_with({ "dedication_message" => { "reuse" => "offer_as_options", "allow_multiple" => true } })
      service = defaults_for(offering)
      service.write!("dedication_message" => "闔家平安")
      service.add!(field: "dedication_message", value: "身體健康")

      assert_empty defaults_for(offering).prefillable
      assert_equal %w[闔家平安 身體健康], defaults_for(offering).suggestions["dedication_message"]
    end

    test "a multi-value prefill is scalarized -- a list is never handed to a single-value control" do
      offering = offering_with({ "dedication_message" => { "reuse" => "prefill", "allow_multiple" => true } })
      service = defaults_for(offering)
      service.write!("dedication_message" => "第一次")
      service.add!(field: "dedication_message", value: "第二次")

      value = defaults_for(offering).prefillable["dedication_message"]
      refute_kind_of Array, value, "passing the accumulated array is the defect this fixes"
      assert_equal "第二次", value, "the most recent answer, not every past answer"
    end

    test "the same field name carries opposite policies on two offerings" do
      # The case that makes per-(offering, field) granularity necessary:
      # dedication_message is a temple-authored incense-item picker on one
      # Shengfukung offering and freeform blessing text on the others, under
      # one shared label.
      picker = offering_with({
        "dedication_message" => { "reuse" => "never", "allow_multiple" => true, "options" => %w[福宴 白米10斤] }
      })
      freeform = offering_with({
        "dedication_message" => { "reuse" => "offer_as_options", "allow_multiple" => true }
      })

      defaults_for(picker).write!("dedication_message" => "白米10斤")
      defaults_for(freeform).write!("dedication_message" => "闔家平安")

      assert_empty defaults_for(picker).read, "a purchase decision must not be remembered"
      assert_equal %w[闔家平安], defaults_for(freeform).suggestions["dedication_message"]
    end

    test "an unrecognised reuse value falls back to the safe default rather than being honoured" do
      offering = offering_with({ "dedication_message" => { "reuse" => "sometimes" } })
      schema = FormSchema.new(offering.metadata["registration_form"])

      assert_equal FormSchema::DEFAULT_REUSE_POLICY, schema.reuse_policy(:dedication_message)
      refute_equal :prefill, schema.reuse_policy(:dedication_message), "a typo must never fall back to the one harmful policy"
    end
  end
end
