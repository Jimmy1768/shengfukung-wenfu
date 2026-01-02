class CreateRecordArchiveTables < ActiveRecord::Migration[7.0]
  def change
    create_table :financial_ledger_entries do |t|
      t.references :user, foreign_key: true
      t.string :entry_type, null: false
      t.string :currency, null: false
      t.string :country_code, null: false, default: "TW"
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.decimal :tax_amount, precision: 15, scale: 2, null: false, default: 0
      t.string :status, null: false, default: "pending"
      t.string :external_reference
      t.date :entry_date, null: false
      t.string :user_name_snapshot
      t.string :user_email_snapshot
      t.jsonb :details, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :financial_ledger_entries, %i[entry_type entry_date], name: "index_financial_entries_on_type_and_date"
    add_index :financial_ledger_entries, :external_reference, unique: true

    create_table :system_audit_logs do |t|
      t.references :admin, foreign_key: true
      t.references :user, foreign_key: true
      t.string :action, null: false
      t.string :target_type
      t.bigint :target_id
      t.string :admin_name_snapshot
      t.string :user_name_snapshot
      t.jsonb :metadata, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    add_index :system_audit_logs, %i[target_type target_id], name: "index_audit_logs_on_target"
    add_index :system_audit_logs, :occurred_at

    create_table :usage_billing_snapshots do |t|
      t.references :user, foreign_key: true
      t.string :usage_type, null: false
      t.string :user_name_snapshot
      t.bigint :quantity, null: false, default: 0
      t.bigint :bytes_consumed, null: false, default: 0
      t.integer :seats_active, null: false, default: 0
      t.date :bucket_date, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :usage_billing_snapshots, %i[usage_type bucket_date], name: "index_usage_snapshots_on_type_and_bucket"

    create_table :message_delivery_archives do |t|
      t.references :user, foreign_key: true
      t.string :channel, null: false
      t.string :recipient, null: false
      t.string :user_name_snapshot
      t.string :recipient_name_snapshot
      t.string :message_key
      t.string :subject
      t.jsonb :payload, null: false, default: {}
      t.string :status, null: false, default: "queued"
      t.datetime :delivered_at
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :message_delivery_archives, %i[channel status], name: "index_message_archives_on_channel_and_status"
    add_index :message_delivery_archives, :message_key

    create_table :account_lifecycle_events do |t|
      t.references :user, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :user_name_snapshot
      t.jsonb :details, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :account_lifecycle_events, :occurred_at
    add_index :account_lifecycle_events, %i[user_id event_type], name: "index_account_lifecycle_on_user_and_type"
  end
end
