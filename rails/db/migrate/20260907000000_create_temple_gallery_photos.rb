# frozen_string_literal: true

# A gallery photo becomes a row instead of a string in a jsonb array.
#
# Before this, an album recorded each photo twice in two unlinked lists:
# photo_urls held the URLs and metadata["media_asset_ids"] held the MediaAsset
# ids, correlated only by happening to be in the same order. Nothing said which
# URL belonged to which asset, so a single photo could not be removed or
# reordered, and destroying an album destroyed the MediaAsset rows while
# leaving their S3 objects orphaned with nothing left pointing at them.
class CreateTempleGalleryPhotos < ActiveRecord::Migration[7.1]
  def up
    create_table :temple_gallery_photos do |t|
      t.references :temple_gallery_entry, null: false, foreign_key: true
      # Null for a pasted URL. Set when the photo came from an upload, which is
      # what makes reclaiming the S3 object possible later.
      t.references :media_asset, null: true, foreign_key: true
      t.string :url, null: false
      t.integer :position, null: false, default: 0
      t.string :status, null: false, default: "active"
      t.timestamps
    end

    add_index :temple_gallery_photos,
      %i[temple_gallery_entry_id position],
      name: "index_gallery_photos_on_entry_and_position"
    add_index :temple_gallery_photos, :status

    backfill!

    remove_column :temple_gallery_entries, :photo_urls
  end

  def down
    add_column :temple_gallery_entries, :photo_urls, :jsonb, default: [], null: false

    execute(<<~SQL.squish)
      UPDATE temple_gallery_entries e
      SET photo_urls = COALESCE((
        SELECT jsonb_agg(p.url ORDER BY p.position)
        FROM temple_gallery_photos p
        WHERE p.temple_gallery_entry_id = e.id AND p.status = 'active'
      ), '[]'::jsonb)
    SQL

    drop_table :temple_gallery_photos
  end

  private

  # The two old lists are positionally correlated and nothing enforced that, so
  # the pairing is reconstructed by index and a mismatch simply leaves
  # media_asset_id null rather than guessing.
  def backfill!
    say_with_time "backfilling gallery photos from photo_urls" do
      rows = select_all(<<~SQL.squish)
        SELECT id, photo_urls, metadata -> 'media_asset_ids' AS asset_ids
        FROM temple_gallery_entries
      SQL

      count = 0
      rows.each do |row|
        urls = parse_json(row["photo_urls"])
        asset_ids = parse_json(row["asset_ids"])

        urls.each_with_index do |url, index|
          next if url.to_s.strip.empty?

          asset_id = asset_ids[index].to_s
          asset_id = nil unless asset_id =~ /\A\d+\z/

          execute(<<~SQL.squish)
            INSERT INTO temple_gallery_photos
              (temple_gallery_entry_id, media_asset_id, url, position, status, created_at, updated_at)
            VALUES
              (#{row['id'].to_i},
               #{asset_id ? asset_id.to_i : 'NULL'},
               #{quote(url.to_s.strip)},
               #{index},
               'active',
               NOW(), NOW())
          SQL
          count += 1
        end
      end
      count
    end
  end

  def parse_json(value)
    return value if value.is_a?(Array)
    return [] if value.nil?

    parsed = JSON.parse(value.to_s)
    parsed.is_a?(Array) ? parsed : []
  rescue JSON::ParserError
    []
  end
end
