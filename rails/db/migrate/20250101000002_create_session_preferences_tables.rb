class CreateSessionPreferencesTables < ActiveRecord::Migration[7.0]
  def change
    create_table :user_preferences do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :locale, null: false, default: "en"
      t.string :timezone, null: false, default: "UTC"
      t.string :currency, null: false, default: "USD"
      t.string :theme, null: false, default: "light"
      t.string :temperature_unit, null: false, default: "F"
      t.string :measurement_system, null: false, default: "imperial"
      t.boolean :twenty_four_hour_time, null: false, default: false
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    create_table :refresh_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.string :device_name
      t.string :device_id
      t.string :platform
      t.datetime :expires_at, null: false
      t.datetime :last_used_at
      t.boolean :revoked, null: false, default: false
      t.jsonb :privacy_flags, default: {}, null: false
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :refresh_tokens, :token_digest, unique: true
    # t.references already adds an index on user_id

    create_table :client_checkins do |t|
      t.references :user, foreign_key: true
      t.string :client_id
      t.string :client_type
      t.datetime :last_ping_at
      t.integer :cache_revision, null: false, default: 1
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :client_checkins, %i[client_id client_type], unique: true

    create_table :privacy_settings do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.boolean :share_data_with_partners, null: false, default: false
      t.boolean :third_party_tracking_enabled, null: false, default: false
      t.boolean :email_tracking_opt_in, null: false, default: true
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

  end
end
