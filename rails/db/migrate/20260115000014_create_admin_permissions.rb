# frozen_string_literal: true

class CreateAdminPermissions < ActiveRecord::Migration[7.1]
  def change
    create_table :admin_permissions do |t|
      t.references :admin_account, null: false, foreign_key: { to_table: :admins }
      t.references :temple, null: false, foreign_key: true
      t.boolean :manage_offerings, null: false, default: false
      t.boolean :manage_registrations, null: false, default: false
      t.boolean :record_cash_payments, null: false, default: false
      t.boolean :view_financials, null: false, default: false
      t.boolean :export_financials, null: false, default: false
      t.boolean :view_guest_lists, null: false, default: false
      t.boolean :manage_permissions, null: false, default: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :admin_permissions, [:admin_account_id, :temple_id], unique: true, name: "index_admin_permissions_on_admin_and_temple"
  end
end
