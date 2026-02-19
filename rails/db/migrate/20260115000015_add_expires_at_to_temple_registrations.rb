# frozen_string_literal: true

class AddExpiresAtToTempleRegistrations < ActiveRecord::Migration[7.1]
  def change
    add_column :temple_registrations, :expires_at, :datetime
    add_index :temple_registrations, [:temple_id, :expires_at], name: "idx_temple_registrations_on_temple_and_expires_at"
  end
end
