class CreateMessagingTables < ActiveRecord::Migration[7.0]
  def change
    create_table :app_messages do |t|
      t.string :key, null: false
      t.string :channel, null: false, default: "web"
      t.string :locale, null: false, default: "en"
      t.jsonb :payload, default: {}, null: false
      t.boolean :active, null: false, default: true
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :app_messages, %i[key channel locale], unique: true

    create_table :push_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :platform, null: false
      t.string :token, null: false
      t.string :device_name
      t.datetime :last_seen_at
      t.boolean :active, null: false, default: true
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :push_tokens, %i[user_id platform token], unique: true, name: "index_push_tokens_on_user_platform_token"

    create_table :notification_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.string :channel, null: false
      t.boolean :enabled, null: false, default: true
      t.boolean :alert_sound_enabled, null: false, default: true
      t.boolean :silent_mode, null: false, default: false
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :notification_preferences, %i[user_id channel], unique: true

    create_table :notification_rules do |t|
      t.string :event_key, null: false
      t.string :channel, null: false
      t.string :template_key
      t.boolean :enabled, null: false, default: true
      t.integer :throttle_interval_seconds, null: false, default: 0
      t.integer :throttle_maximum, null: false, default: 0
      t.boolean :requires_opt_in, null: false, default: true
      t.jsonb :audience_filters, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :notification_rules, %i[event_key channel], unique: true, name: "index_notification_rules_on_event_and_channel"

    create_table :notifications do |t|
      t.references :notification_rule, foreign_key: true
      t.references :user, foreign_key: true
      t.string :channel, null: false
      t.string :status, null: false, default: "pending"
      t.string :recipient
      t.string :message_key
      t.jsonb :payload, null: false, default: {}
      t.jsonb :delivery_context, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.datetime :scheduled_at
      t.datetime :sent_at
      t.datetime :failed_at
      t.string :provider_message_id
      t.text :error_details
      t.timestamps
    end

    add_index :notifications, :status
    add_index :notifications, :scheduled_at
    add_index :notifications, %i[channel recipient], name: "index_notifications_on_channel_and_recipient"
  end
end
