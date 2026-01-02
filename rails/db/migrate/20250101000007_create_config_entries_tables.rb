class CreateConfigEntriesTables < ActiveRecord::Migration[7.0]
  def change
    create_table :config_entries do |t|
      t.string :key, null: false
      t.string :scope_type, null: false, default: "system"
      t.bigint :scope_id
      t.jsonb :value, null: false, default: {}
      t.string :context
      t.text :description
      t.boolean :locked, null: false, default: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :config_entries, %i[key scope_type scope_id], unique: true, name: "index_config_entries_on_key_and_scope"

    create_table :feature_flag_rollouts do |t|
      t.references :config_entry, null: false, foreign_key: true
      t.boolean :enabled_by_default, null: false, default: true
      t.integer :rollout_percentage, null: false, default: 100
      t.string :prerequisite_key
      t.datetime :starts_at
      t.datetime :ends_at
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :feature_flag_rollouts, :prerequisite_key
  end
end
