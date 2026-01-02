class CreateBackgroundTaskRegistry < ActiveRecord::Migration[7.0]
  def change
    create_table :background_tasks do |t|
      t.string :task_key, null: false
      t.string :status, null: false, default: "pending"
      t.integer :attempts, null: false, default: 0
      t.string :queue_name
      t.integer :priority, null: false, default: 0
      t.datetime :scheduled_at
      t.datetime :started_at
      t.datetime :finished_at
      t.jsonb :payload, null: false, default: {}
      t.text :last_error
      t.string :lock_owner
      t.datetime :locked_at
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :background_tasks, :task_key
    add_index :background_tasks, :status
    add_index :background_tasks, :scheduled_at
  end
end
