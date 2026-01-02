class CreateAdminControlTables < ActiveRecord::Migration[7.0]
  def change
    create_table :admins do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :role, null: false, default: "staff"
      t.integer :access_level, null: false, default: 1
      t.boolean :active, null: false, default: true
      t.datetime :last_signed_in_at
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    create_table :dev_mode_tokens do |t|
      t.references :admin, null: false, foreign_key: true
      t.string :token, null: false
      t.string :purpose
      t.datetime :expires_at
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :dev_mode_tokens, :token, unique: true
  end
end
