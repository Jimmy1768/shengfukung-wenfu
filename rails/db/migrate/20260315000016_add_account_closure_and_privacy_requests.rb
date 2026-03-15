class AddAccountClosureAndPrivacyRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :account_status, :string, null: false, default: "active"
    add_column :users, :closed_at, :datetime
    add_column :users, :closure_reason, :string
    add_column :users, :anonymized_at, :datetime
    add_reference :users, :closed_by_user, foreign_key: { to_table: :users }

    add_index :users, :account_status
    add_index :users, :closed_at

    create_table :privacy_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :operator_user, foreign_key: { to_table: :users }
      t.string :request_type, null: false
      t.string :status, null: false, default: "pending"
      t.string :submitted_via, null: false, default: "web"
      t.datetime :requested_at, null: false
      t.datetime :resolved_at
      t.text :notes
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :privacy_requests, %i[user_id request_type status], name: "index_privacy_requests_on_user_type_status"
    add_index :privacy_requests, :requested_at
  end
end
