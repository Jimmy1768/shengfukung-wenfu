class CreateAnalyticsExportTables < ActiveRecord::Migration[7.0]
  def change
    create_table :data_export_jobs do |t|
      t.string :export_key, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :scheduled_at
      t.datetime :started_at
      t.datetime :finished_at
      t.datetime :range_start
      t.datetime :range_end
      t.string :destination, null: false, default: "s3"
      t.jsonb :filters, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :data_export_jobs, :export_key
    add_index :data_export_jobs, :status

    create_table :data_export_payloads do |t|
      t.references :data_export_job, null: false, foreign_key: true
      t.string :storage_location, null: false
      t.string :checksum
      t.bigint :bytes, null: false, default: 0
      t.integer :record_count, null: false, default: 0
      t.datetime :available_at, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :data_export_payloads, :available_at
  end
end
