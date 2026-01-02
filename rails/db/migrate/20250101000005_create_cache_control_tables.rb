class CreateCacheControlTables < ActiveRecord::Migration[7.0]
  def change
    create_table :client_cache_states do |t|
      t.references :user, null: false, foreign_key: true
      t.references :client_checkin, null: false, foreign_key: true
      t.string :state_key, null: false
      t.boolean :needs_refresh, null: false, default: true
      t.integer :version, null: false, default: 0
      t.string :context_reference
      t.jsonb :context_data, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :client_cache_states, %i[user_id client_checkin_id state_key], unique: true, name: "index_cache_states_on_user_client_and_state_key"
    add_index :client_cache_states, %i[state_key needs_refresh], name: "index_cache_states_on_state_key_and_status"

    create_table :client_cache_metrics do |t|
      t.references :user, foreign_key: true
      t.references :client_checkin, foreign_key: true
      t.string :metric_key, null: false
      t.bigint :hits_count, null: false, default: 0
      t.bigint :misses_count, null: false, default: 0
      t.bigint :refresh_count, null: false, default: 0
      t.bigint :bytes_sent, null: false, default: 0
      t.datetime :last_refreshed_at
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :client_cache_metrics, %i[user_id metric_key], name: "index_cache_metrics_on_user_and_metric_key"
    add_index :client_cache_metrics, %i[client_checkin_id metric_key], name: "index_cache_metrics_on_client_and_metric_key"

    create_table :data_transfer_logs do |t|
      t.references :user, foreign_key: true
      t.references :client_checkin, foreign_key: true
      t.string :transfer_key
      t.string :direction, null: false
      t.bigint :bytes_transferred, null: false
      t.datetime :occurred_at, null: false
      t.date :bucket_date, null: false
      t.string :payload_type
      t.string :request_route
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :data_transfer_logs, :bucket_date
    add_index :data_transfer_logs, %i[user_id transfer_key], name: "index_transfer_logs_on_user_and_transfer_key"
    add_index :data_transfer_logs, %i[client_checkin_id transfer_key], name: "index_transfer_logs_on_client_and_transfer_key"

    create_table :cache_repair_tasks do |t|
      t.string :repair_key, null: false
      t.references :user, foreign_key: true
      t.references :client_checkin, foreign_key: true
      t.jsonb :context_data, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.text :error_details
      t.datetime :scheduled_for
      t.datetime :attempted_at
      t.datetime :resolved_at
      t.timestamps
    end

    add_index :cache_repair_tasks, :repair_key, name: "index_cache_repair_tasks_on_repair_key"
    add_index :cache_repair_tasks, :status
    add_index :cache_repair_tasks, :scheduled_for
  end
end
