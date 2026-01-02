class CreateComplianceTables < ActiveRecord::Migration[7.0]
  def change
    create_table :data_anomalies do |t|
      t.string :detector_key, null: false
      t.string :record_type
      t.bigint :record_id
      t.string :severity, null: false, default: "warning"
      t.string :status, null: false, default: "open"
      t.jsonb :details, null: false, default: {}
      t.datetime :detected_at, null: false
      t.datetime :resolved_at
      t.text :resolution_notes
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :data_anomalies, %i[record_type record_id], name: "index_data_anomalies_on_record"
    add_index :data_anomalies, :status
    add_index :data_anomalies, :detector_key

    create_table :agreements do |t|
      t.string :key, null: false
      t.integer :version, null: false, default: 1
      t.string :title, null: false
      t.text :body, null: false
      t.date :effective_on, null: false
      t.boolean :archived, null: false, default: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :agreements, %i[key version], unique: true

    create_table :agreement_acceptances do |t|
      t.references :agreement, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :accepted_at, null: false
      t.string :ip_address
      t.string :user_agent
      t.text :body_snapshot, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :agreement_acceptances, %i[agreement_id user_id], name: "index_agreement_acceptances_on_agreement_and_user"
  end
end
