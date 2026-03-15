# frozen_string_literal: true

class CreateTempleAssistanceRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :temple_assistance_requests do |t|
      t.references :temple, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :temple_registration, foreign_key: { to_table: :temple_registrations }
      t.string :status, null: false, default: "open"
      t.datetime :requested_at, null: false
      t.datetime :closed_at
      t.bigint :closed_by_admin_id
      t.string :channel, null: false
      t.string :message
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_foreign_key :temple_assistance_requests, :admins, column: :closed_by_admin_id
    add_index :temple_assistance_requests, %i[temple_id status requested_at], name: "idx_temple_assistance_requests_queue"
    add_index :temple_assistance_requests, %i[temple_id user_id temple_registration_id status], name: "idx_temple_assistance_requests_dedupe"
  end
end
