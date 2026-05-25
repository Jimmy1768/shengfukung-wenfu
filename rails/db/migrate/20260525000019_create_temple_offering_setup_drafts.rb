# frozen_string_literal: true

class CreateTempleOfferingSetupDrafts < ActiveRecord::Migration[7.1]
  def change
    create_table :temple_offering_setup_drafts do |t|
      t.references :temple, null: false, foreign_key: true
      t.references :created_by_admin, foreign_key: { to_table: :admins }
      t.references :reviewed_by_admin, foreign_key: { to_table: :admins }
      t.references :applied_by_admin, foreign_key: { to_table: :admins }
      t.string :status, null: false, default: "draft"
      t.string :offering_kind, null: false
      t.string :slug, null: false
      t.string :label, null: false
      t.string :registration_period_key
      t.integer :price_cents, null: false, default: 0
      t.string :currency, null: false, default: "TWD"
      t.jsonb :setup_payload, null: false, default: {}
      t.jsonb :generated_template, null: false, default: {}
      t.text :review_notes
      t.datetime :submitted_at
      t.datetime :reviewed_at
      t.datetime :applied_at
      t.timestamps
    end

    add_index :temple_offering_setup_drafts,
      [:temple_id, :slug],
      name: "idx_offering_setup_drafts_on_temple_slug"
    add_index :temple_offering_setup_drafts,
      [:temple_id, :status],
      name: "idx_offering_setup_drafts_on_temple_status"
  end
end
