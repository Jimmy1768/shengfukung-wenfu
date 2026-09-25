# frozen_string_literal: true

# Renames the demo temple's slug in place: shengfukung-wenfu -> shengfukung-demo.
#
# Why a migration rather than a script. The slug lives in two places that must
# agree -- shared/app_constants/project.json and this record -- because
# TempleContextResolver falls back to AppConstants::Project.slug to decide which
# temple the public site is serving. Shipping the data change as a migration
# puts both halves in one commit and runs it everywhere the code goes, so a
# deployment cannot land with the file renamed and the record not.
#
# In place, by id. The record keeps its temple_id, so everything that attaches
# by temple_id -- registrations above all -- stays attached. Nothing here
# creates or destroys a temple.
#
# This renames the temple, not the infrastructure. The systemd units, the env
# file, /var/www/shengfukung-wenfu and the checkout folders keep their names;
# those move in Phase C, in a sudo window.
class RenameDemoTempleSlug < ActiveRecord::Migration[7.1]
  OLD_SLUG = "shengfukung-wenfu"
  NEW_SLUG = "shengfukung-demo"

  def up
    rename_slug(from: OLD_SLUG, to: NEW_SLUG)
  end

  def down
    rename_slug(from: NEW_SLUG, to: OLD_SLUG)
  end

  private

  # A no-op when the source slug is absent, which is the normal case on a fresh
  # database, in CI, and on any second run. It is also a no-op when the
  # destination already exists, so this can never collapse two temples into one
  # by renaming onto an occupied slug.
  def rename_slug(from:, to:)
    temples = quoted_table("temples")
    existing = select_value("SELECT COUNT(*) FROM #{temples} WHERE slug = #{quote(to)}").to_i

    if existing.positive?
      say "#{to} already exists; leaving the data alone"
      return
    end

    updated = execute(
      "UPDATE #{temples} SET slug = #{quote(to)}, updated_at = NOW() WHERE slug = #{quote(from)}"
    ).cmd_tuples

    if updated.zero?
      say "no temple with slug #{from}; nothing to rename"
    else
      say "renamed #{updated} temple from #{from} to #{to}"
    end
  end

  def quoted_table(name)
    connection.quote_table_name(name)
  end

  def quote(value)
    connection.quote(value)
  end
end
