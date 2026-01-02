class CreateAuthCoreTables < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :encrypted_password, null: false
      t.string :english_name, null: false
      t.string :native_name
      t.string :national_id
      t.date :birthdate
      t.string :password_reset_token
      t.datetime :password_reset_sent_at
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :users, :email, unique: true

    create_table :dependents do |t|
      t.string :english_name, null: false
      t.string :native_name
      t.string :national_id
      t.date :birthdate
      t.string :relationship_label
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    create_table :user_dependents do |t|
      t.references :user, null: false, foreign_key: true
      t.references :dependent, null: false, foreign_key: true
      t.string :role, null: false, default: "caretaker"
      t.string :relationship_label
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :user_dependents, %i[user_id dependent_id], unique: true, name: "index_user_dependents_on_user_and_dependent"

    create_table :oauth_identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :provider_uid, null: false
      t.string :email
      t.jsonb :credentials, default: {}, null: false
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :oauth_identities, %i[provider provider_uid], unique: true, name: "index_oauth_identities_on_provider_and_uid"
  end
end
