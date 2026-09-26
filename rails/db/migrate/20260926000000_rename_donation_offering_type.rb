# frozen_string_literal: true

# 香油錢 is a physical product, not a donation, and the code's name for it read
# as a charitable donation under Apple's store rules. The Director, 2026-09-26:
# change the name. This renames what is already stored so the data agrees with
# the code that ships beside it.
#
# Two renames, and they are separate facts:
#
#   the offering TYPE   "donation" -> "incense", on every temple_events,
#                       temple_services and temple_gatherings row whose
#                       metadata says so. Nothing branches on the value -- it is
#                       a label on the admin form, a filter on two admin lists
#                       and a serializer field -- so this changes no behaviour.
#
#   the demo SERVICE    slug incense-donation -> incense-oil, title 香油捐獻 ->
#                       香油錢, and the copies of those names that
#                       Offerings::TemplateParity#template_metadata writes into
#                       the row's metadata when temples:bootstrap upserts it.
#
# The metadata keys are not guessed. template_parity.rb:122-134 writes
# offering_type, form_defaults (which repeats offering_type), form_label (the
# template's label) and registration_form (which carries the fulfilment
# section's title). That is exactly the two "donation" and two "捐獻" the
# production row was reported to hold.
#
# In place, by id: the rows keep their ids, so registrations and payments
# attached to them stay attached. Follows
# 20260925000000_rename_demo_temple_slug.rb.
class RenameDonationOfferingType < ActiveRecord::Migration[7.1]
  OLD_TYPE = "donation"
  NEW_TYPE = "incense"
  OLD_SLUG = "incense-donation"
  NEW_SLUG = "incense-oil"
  OLD_TITLE = "香油捐獻"
  NEW_TITLE = "香油錢"
  OLD_SECTION = "捐獻用途"
  NEW_SECTION = "辦理方式"

  # Defined here rather than reaching for the app's models: a migration has to
  # keep meaning what it meant when it was written, and TempleEvent and its
  # siblings are free to change.
  class Event < ActiveRecord::Base
    self.table_name = "temple_events"
  end

  class Service < ActiveRecord::Base
    self.table_name = "temple_services"
  end

  class Gathering < ActiveRecord::Base
    self.table_name = "temple_gatherings"
  end

  TABLES = [Event, Service, Gathering].freeze

  def up
    rename(type_from: OLD_TYPE, type_to: NEW_TYPE,
           slug_from: OLD_SLUG, slug_to: NEW_SLUG,
           title_from: OLD_TITLE, title_to: NEW_TITLE,
           section_from: OLD_SECTION, section_to: NEW_SECTION)
  end

  def down
    rename(type_from: NEW_TYPE, type_to: OLD_TYPE,
           slug_from: NEW_SLUG, slug_to: OLD_SLUG,
           title_from: NEW_TITLE, title_to: OLD_TITLE,
           section_from: NEW_SECTION, section_to: OLD_SECTION)
  end

  private

  def rename(type_from:, type_to:, slug_from:, slug_to:, title_from:, title_to:, section_from:, section_to:)
    rename_service_slugs(slug_from, slug_to, title_from, title_to, section_from, section_to)
    rename_offering_types(type_from, type_to)
  end

  # Renaming onto an occupied slug would give one temple two services that every
  # lookup by slug treats as one. Refuse instead, and say which temple, so
  # whoever hits it can decide -- merging is not a decision a migration makes.
  def rename_service_slugs(slug_from, slug_to, title_from, title_to, section_from, section_to)
    TABLES.each do |model|
      rows = model.where(slug: slug_from)
      next if rows.none?

      rows.each do |row|
        if model.where(temple_id: row.temple_id, slug: slug_to).exists?
          raise ActiveRecord::IrreversibleMigration,
            "temple #{row.temple_id} already has a #{model.table_name} row with slug " \
            "#{slug_to}, so renaming #{slug_from} onto it would leave two rows that " \
            "every lookup by slug treats as one. Resolve the duplicate by hand first."
        end

        row.update_columns(
          slug: slug_to,
          title: row.title == title_from ? title_to : row.title,
          metadata: rename_in_metadata(row.metadata, title_from, title_to, section_from, section_to)
        )
        say "renamed #{model.table_name} ##{row.id} #{slug_from} -> #{slug_to}"
      end
    end
  end

  # Only the strings this rename owns, and only where they appear. A blanket
  # substitution of 捐獻 would be wrong: 香油捐獻 becomes 香油錢 and 捐獻用途
  # becomes 辦理方式, which share no replacement.
  def rename_in_metadata(metadata, title_from, title_to, section_from, section_to)
    return metadata unless metadata.is_a?(Hash)

    data = deep_dup(metadata)
    data["form_label"] = title_to if data["form_label"] == title_from
    walk(data) { |value| value == section_from ? section_to : value }
  end

  def rename_offering_types(type_from, type_to)
    TABLES.each do |model|
      updated = 0
      model.where("metadata ->> 'offering_type' = ?", type_from).each do |row|
        data = deep_dup(row.metadata)
        data["offering_type"] = type_to
        if data["form_defaults"].is_a?(Hash) && data["form_defaults"]["offering_type"] == type_from
          data["form_defaults"]["offering_type"] = type_to
        end
        row.update_columns(metadata: data)
        updated += 1
      end

      if updated.zero?
        say "no #{model.table_name} rows with offering_type #{type_from}"
      else
        say "retyped #{updated} #{model.table_name} rows #{type_from} -> #{type_to}"
      end
    end
  end

  def walk(value, &block)
    case value
    when Hash then value.transform_values { |v| walk(v, &block) }
    when Array then value.map { |v| walk(v, &block) }
    else block.call(value)
    end
  end

  def deep_dup(value)
    case value
    when Hash then value.each_with_object({}) { |(k, v), h| h[k] = deep_dup(v) }
    when Array then value.map { |v| deep_dup(v) }
    else value
    end
  end
end
