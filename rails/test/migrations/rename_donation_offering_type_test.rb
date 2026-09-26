require "test_helper"
require Rails.root.join("db/migrate/20260926000000_rename_donation_offering_type.rb")

# 香油錢 is a physical product, not a donation. This renames what is stored so
# the data agrees with the code shipped beside it.
#
# The metadata built here mirrors what Offerings::TemplateParity#template_metadata
# writes when temples:bootstrap upserts the demo template -- offering_type,
# form_defaults repeating it, form_label, and registration_form carrying the
# fulfilment section title. Those four are where the old names are stored, and
# the point of the fixture is that all four move together.
class RenameDonationOfferingTypeTest < ActiveSupport::TestCase
  def migration
    RenameDonationOfferingType.new.tap { |m| m.verbose = false }
  end

  def bootstrapped_metadata(type: "donation", label: "香油捐獻", section: "捐獻用途")
    {
      "offering_type" => type,
      "form_defaults" => { "offering_type" => type, "currency" => "TWD" },
      "form_label" => label,
      "registration_form" => {
        "sections" => [
          { "key" => "details", "title" => "服務內容" },
          { "key" => "fulfillment", "title" => section, "fields" => %w[fulfillment_method] }
        ]
      }
    }
  end

  def create_service(temple:, slug: "incense-donation", title: "香油捐獻", metadata: bootstrapped_metadata)
    TempleService.create!(
      temple: temple, slug: slug, title: title,
      price_cents: 500, currency: "TWD", metadata: metadata
    )
  end

  def section_title(service)
    service.reload.metadata.dig("registration_form", "sections", 1, "title")
  end

  test "up renames the type, the slug, the title and every stored copy of the names" do
    service = create_service(temple: create_temple)

    migration.up
    service.reload

    assert_equal "incense-oil", service.slug
    assert_equal "香油錢", service.title
    assert_equal "incense", service.metadata["offering_type"]
    assert_equal "incense", service.metadata.dig("form_defaults", "offering_type"),
      "form_defaults repeats offering_type and must move with it"
    assert_equal "香油錢", service.metadata["form_label"]
    assert_equal "辦理方式", section_title(service)
  end

  test "the row keeps its id, so registrations stay attached" do
    temple = create_temple
    service = create_service(temple: temple)

    assert_no_difference -> { TempleService.count } do
      migration.up
    end

    assert_equal service.id, TempleService.find_by(slug: "incense-oil").id
  end

  # Every other offering of this type is retyped, whatever it is called.
  test "it retypes other offerings without touching their names" do
    temple = create_temple
    other = create_service(
      temple: temple, slug: "year-round-blessing", title: "全年祈福服務",
      metadata: { "offering_type" => "donation", "seeded_by" => "bootstrap" }
    )

    migration.up
    other.reload

    assert_equal "incense", other.metadata["offering_type"]
    assert_equal "year-round-blessing", other.slug, "only the demo service is renamed"
    assert_equal "全年祈福服務", other.title
  end

  test "offerings of other types are left alone" do
    temple = create_temple
    lamp = create_service(
      temple: temple, slug: "lamp-service", title: "點燈",
      metadata: { "offering_type" => "lamp" }
    )

    migration.up

    assert_equal "lamp", lamp.reload.metadata["offering_type"]
  end

  test "down restores every name" do
    service = create_service(temple: create_temple)

    migration.up
    migration.down
    service.reload

    assert_equal "incense-donation", service.slug
    assert_equal "香油捐獻", service.title
    assert_equal "donation", service.metadata["offering_type"]
    assert_equal "donation", service.metadata.dig("form_defaults", "offering_type")
    assert_equal "香油捐獻", service.metadata["form_label"]
    assert_equal "捐獻用途", section_title(service)
  end

  # A fresh database, CI, and any second run.
  test "it is a no-op when there is nothing to rename" do
    create_temple

    assert_no_difference -> { TempleService.count } do
      assert_nothing_raised { migration.up }
    end
  end

  test "running it twice changes nothing the second time" do
    service = create_service(temple: create_temple)

    migration.up
    migration.up

    assert_equal "incense-oil", service.reload.slug
    assert_equal "incense", service.metadata["offering_type"]
  end

  # Renaming onto an occupied slug would leave one temple with two services that
  # every lookup by slug treats as one. Merging is not a migration's decision.
  test "it refuses rather than merging when the new slug is taken" do
    temple = create_temple
    old = create_service(temple: temple)
    taken = create_service(temple: temple, slug: "incense-oil", title: "香油錢",
                           metadata: { "offering_type" => "incense" })

    error = assert_raises(ActiveRecord::IrreversibleMigration) { migration.up }
    assert_match "already has", error.message

    assert_equal "incense-donation", old.reload.slug, "the old row must be left alone"
    assert_equal "incense-oil", taken.reload.slug
  end

  # The same slug in two different temples is not a conflict.
  test "two temples each carrying the service are both renamed" do
    a = create_service(temple: create_temple)
    b = create_service(temple: create_temple)

    migration.up

    assert_equal "incense-oil", a.reload.slug
    assert_equal "incense-oil", b.reload.slug
  end
end
