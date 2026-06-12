require "test_helper"

module Offerings
  class SetupFieldCatalogTest < ActiveSupport::TestCase
    test "exposes supported fields with labels groups and option metadata" do
      field = Offerings::SetupFieldCatalog.find("fulfillment_method")

      assert field
      assert_equal "fulfillment_method", field.key
      assert_equal "operations", field.group
      assert field.label.present?
      assert field.hint.present?
      assert field.option_bearing?
      assert_includes Offerings::SetupFieldCatalog.supported_keys, "logistics_notes"
      assert_includes Offerings::SetupFieldCatalog.supported_keys, "price_cents"
      assert_includes Offerings::SetupFieldCatalog.supported_keys, "currency"
      assert_includes Offerings::SetupFieldCatalog.option_bearing_keys, "lamp_type"
      assert_includes Offerings::SetupFieldCatalog.option_bearing_keys, "currency"
      refute Offerings::SetupFieldCatalog.option_bearing?("logistics_notes")
    end

    test "keeps registration fields distinct from admin setup fields" do
      assert Offerings::SetupFieldCatalog.registration_field?("ancestor_placard_name")
      refute Offerings::SetupFieldCatalog.supported?("ancestor_placard_name")
    end

    test "exposes registration fields grouped by schema section" do
      grouped = Offerings::SetupFieldCatalog.registration_grouped_fields

      assert_includes grouped.keys, "order"
      assert_includes grouped.keys, "contact"
      assert_includes grouped.keys, "logistics"
      assert_includes grouped.keys, "ritual_metadata"
      assert Offerings::SetupFieldCatalog.registration_field_supported?("ritual_metadata", "ancestor_placard_name")
      refute Offerings::SetupFieldCatalog.registration_field_supported?("ritual_metadata", "primary_contact")
      assert_equal %w[quantity unit_price_cents currency], Offerings::SetupFieldCatalog.default_registration_fields["order"]
    end
  end
end
