class CreateApiProtectionTables < ActiveRecord::Migration[7.0]
  def change
    create_table :api_usage_logs do |t|
      t.references :user, foreign_key: true
      t.string :access_key
      t.string :client_identifier
      t.string :ip_address
      t.string :request_path, null: false
      t.string :http_method, null: false, default: "GET"
      t.integer :status_code
      t.integer :response_time_ms
      t.datetime :occurred_at, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :api_usage_logs, :occurred_at
    add_index :api_usage_logs, %i[access_key occurred_at], name: "index_api_usage_on_key_and_time"
    add_index :api_usage_logs, :ip_address

    create_table :api_request_counters do |t|
      t.string :scope_type, null: false
      t.bigint :scope_id
      t.string :bucket, null: false
      t.integer :count, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :api_request_counters, %i[scope_type scope_id bucket], unique: true, name: "index_api_request_counters_on_scope_and_bucket"

    create_table :blacklist_entries do |t|
      t.string :scope_type, null: false
      t.bigint :scope_id
      t.string :reason, null: false
      t.datetime :expires_at
      t.boolean :active, null: false, default: true
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :blacklist_entries, %i[scope_type scope_id active], name: "index_blacklist_entries_on_scope_and_state"
  end
end
