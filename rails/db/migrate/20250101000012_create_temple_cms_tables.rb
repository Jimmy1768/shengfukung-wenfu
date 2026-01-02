# frozen_string_literal: true

class CreateTempleCmsTables < ActiveRecord::Migration[7.1]
  def change
    create_table :temples do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.string :tagline
      t.string :primary_image_url
      t.text :hero_copy
      t.text :about_html
      t.jsonb :contact_info, null: false, default: {}
      t.jsonb :service_times, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.boolean :published, null: false, default: true
      t.timestamps
    end
    add_index :temples, :slug, unique: true

    create_table :temple_pages do |t|
      t.references :temple, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :title
      t.string :slug
      t.integer :position, null: false, default: 0
      t.jsonb :meta, null: false, default: {}
      t.timestamps
    end
    add_index :temple_pages, %i[temple_id kind], unique: true
    add_index :temple_pages, %i[temple_id slug]

    create_table :temple_sections do |t|
      t.references :temple_page, null: false, foreign_key: true
      t.string :section_type, null: false
      t.string :title
      t.text :body
      t.jsonb :payload, null: false, default: {}
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :media_assets do |t|
      t.references :temple, null: false, foreign_key: true
      t.string :role, null: false
      t.string :file_uid, null: false
      t.string :alt_text
      t.string :credit
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :media_assets, :role

    create_table :admin_temple_memberships do |t|
      t.references :admin_account, null: false, foreign_key: { to_table: :admins }
      t.references :temple, null: false, foreign_key: true
      t.string :role, null: false, default: "staff"
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :admin_temple_memberships, %i[admin_account_id temple_id], unique: true, name: "index_memberships_on_admin_and_temple"

    add_reference :system_audit_logs, :temple, foreign_key: true
  end
end
