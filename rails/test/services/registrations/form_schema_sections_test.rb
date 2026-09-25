# frozen_string_literal: true

require "test_helper"

module Registrations
  # Regression coverage for a bug that survived precisely because the tests
  # and the production configs used DIFFERENT shapes. Every real temple yml
  # declares sections as `{ fields: [...] }`; every test used the bare-Array
  # shorthand. normalize_field_config handled the shorthand and let the Hash
  # fall through to the section's FULL default list, so offerings rendered
  # fields they had never declared -- green suite, wrong production behavior.
  #
  # These assert the shipped shape first, deliberately.
  class FormSchemaSectionsTest < ActiveSupport::TestCase
    def fields(override)
      FormSchema.new({ "sections" => { "ritual_metadata" => override } }).fields_for(:ritual_metadata)
    end

    test "the { fields: [...] } shape every real temple config uses is honoured" do
      assert_equal %i[dedication_message], fields({ "fields" => ["dedication_message"] })
    end

    test "the shape works with symbol keys too, since config is symbolized upstream" do
      assert_equal %i[dedication_message], fields({ fields: [:dedication_message] })
    end

    test "an explicitly empty fields list means empty, not defaults" do
      assert_empty fields({ "fields" => [] })
    end

    test "a Hash declaring something OTHER than fields still falls back to defaults" do
      # It is describing the section, not declaring it empty.
      assert_equal FormSchema::DEFAULT_SECTIONS[:ritual_metadata], fields({ "label" => "Ceremony" })
    end

    test "the bare-Array shorthand keeps working" do
      assert_equal %i[dedication_message], fields(["dedication_message"])
    end

    test "false disables the section and absent/true/nil yield defaults" do
      defaults = FormSchema::DEFAULT_SECTIONS[:ritual_metadata]

      assert_empty fields(false)
      assert_equal defaults, fields(nil)
      assert_equal defaults, fields(true)
      assert_equal defaults, FormSchema.new({}).fields_for(:ritual_metadata)
    end

    test "a declared subset does not leak sibling defaults into include_field?" do
      schema = FormSchema.new({ "sections" => { "ritual_metadata" => { "fields" => ["dedication_message"] } } })

      assert schema.include_field?(:ritual_metadata, :dedication_message)
      refute schema.include_field?(:ritual_metadata, :incense_option),
        "incense_option was rendering on offerings that never declared it"
      refute schema.include_field?(:ritual_metadata, :ancestor_placard_name)
    end

    test "the real pilot-temple config renders exactly what it declares" do
      config = YAML.safe_load_file(Rails.root.join("db/temples/offerings/shengfukung-demo.yml"))
      offerings = config["offerings"] || config.values.find { |value| value.is_a?(Array) }

      offerings.each do |offering|
        form = offering["registration_form"] || offering.dig("metadata", "registration_form")
        next if form.blank?

        schema = FormSchema.new(form)
        %w[contact logistics ritual_metadata].each do |section|
          raw = form.dig("sections", section)
          declared = case raw
                     when Hash then Array(raw["fields"])
                     when false, nil then []
                     else Array(raw)
                     end
          assert_equal declared.map(&:to_s).sort,
            schema.fields_for(section).map(&:to_s).sort,
            "#{offering['slug']} / #{section} must render exactly its declared fields"
        end
      end
    end
  end
end
