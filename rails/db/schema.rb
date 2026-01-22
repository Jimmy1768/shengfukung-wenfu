# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_01_15_000014) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_lifecycle_events", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "event_type", null: false
    t.string "user_name_snapshot"
    t.jsonb "details", default: {}, null: false
    t.datetime "occurred_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["occurred_at"], name: "index_account_lifecycle_events_on_occurred_at"
    t.index ["user_id", "event_type"], name: "index_account_lifecycle_on_user_and_type"
    t.index ["user_id"], name: "index_account_lifecycle_events_on_user_id"
  end

  create_table "admin_permissions", force: :cascade do |t|
    t.bigint "admin_account_id", null: false
    t.bigint "temple_id", null: false
    t.boolean "manage_offerings", default: false, null: false
    t.boolean "manage_registrations", default: false, null: false
    t.boolean "record_cash_payments", default: false, null: false
    t.boolean "view_financials", default: false, null: false
    t.boolean "export_financials", default: false, null: false
    t.boolean "view_guest_lists", default: false, null: false
    t.boolean "manage_permissions", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_account_id", "temple_id"], name: "index_admin_permissions_on_admin_and_temple", unique: true
    t.index ["admin_account_id"], name: "index_admin_permissions_on_admin_account_id"
    t.index ["temple_id"], name: "index_admin_permissions_on_temple_id"
  end

  create_table "admin_temple_memberships", force: :cascade do |t|
    t.bigint "admin_account_id", null: false
    t.bigint "temple_id", null: false
    t.string "role", default: "staff", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_account_id", "temple_id"], name: "index_memberships_on_admin_and_temple", unique: true
    t.index ["admin_account_id"], name: "index_admin_temple_memberships_on_admin_account_id"
    t.index ["temple_id"], name: "index_admin_temple_memberships_on_temple_id"
  end

  create_table "admins", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "role", default: "staff", null: false
    t.integer "access_level", default: 1, null: false
    t.boolean "active", default: true, null: false
    t.datetime "last_signed_in_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_admins_on_user_id", unique: true
  end

  create_table "agreement_acceptances", force: :cascade do |t|
    t.bigint "agreement_id", null: false
    t.bigint "user_id", null: false
    t.datetime "accepted_at", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.text "body_snapshot", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agreement_id", "user_id"], name: "index_agreement_acceptances_on_agreement_and_user"
    t.index ["agreement_id"], name: "index_agreement_acceptances_on_agreement_id"
    t.index ["user_id"], name: "index_agreement_acceptances_on_user_id"
  end

  create_table "agreements", force: :cascade do |t|
    t.string "key", null: false
    t.integer "version", default: 1, null: false
    t.string "title", null: false
    t.text "body", null: false
    t.date "effective_on", null: false
    t.boolean "archived", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key", "version"], name: "index_agreements_on_key_and_version", unique: true
  end

  create_table "api_request_counters", force: :cascade do |t|
    t.string "scope_type", null: false
    t.bigint "scope_id"
    t.string "bucket", null: false
    t.integer "count", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scope_type", "scope_id", "bucket"], name: "index_api_request_counters_on_scope_and_bucket", unique: true
  end

  create_table "api_usage_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.string "access_key"
    t.string "client_identifier"
    t.string "ip_address"
    t.string "request_path", null: false
    t.string "http_method", default: "GET", null: false
    t.integer "status_code"
    t.integer "response_time_ms"
    t.datetime "occurred_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_key", "occurred_at"], name: "index_api_usage_on_key_and_time"
    t.index ["ip_address"], name: "index_api_usage_logs_on_ip_address"
    t.index ["occurred_at"], name: "index_api_usage_logs_on_occurred_at"
    t.index ["user_id"], name: "index_api_usage_logs_on_user_id"
  end

  create_table "app_messages", force: :cascade do |t|
    t.string "key", null: false
    t.string "channel", default: "web", null: false
    t.string "locale", default: "en", null: false
    t.jsonb "payload", default: {}, null: false
    t.boolean "active", default: true, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key", "channel", "locale"], name: "index_app_messages_on_key_and_channel_and_locale", unique: true
  end

  create_table "background_tasks", force: :cascade do |t|
    t.string "task_key", null: false
    t.string "status", default: "pending", null: false
    t.integer "attempts", default: 0, null: false
    t.string "queue_name"
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.jsonb "payload", default: {}, null: false
    t.text "last_error"
    t.string "lock_owner"
    t.datetime "locked_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scheduled_at"], name: "index_background_tasks_on_scheduled_at"
    t.index ["status"], name: "index_background_tasks_on_status"
    t.index ["task_key"], name: "index_background_tasks_on_task_key"
  end

  create_table "blacklist_entries", force: :cascade do |t|
    t.string "scope_type", null: false
    t.bigint "scope_id"
    t.string "reason", null: false
    t.datetime "expires_at"
    t.boolean "active", default: true, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scope_type", "scope_id", "active"], name: "index_blacklist_entries_on_scope_and_state"
  end

  create_table "cache_repair_tasks", force: :cascade do |t|
    t.string "repair_key", null: false
    t.bigint "user_id"
    t.bigint "client_checkin_id"
    t.jsonb "context_data", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "status", default: "pending", null: false
    t.text "error_details"
    t.datetime "scheduled_for"
    t.datetime "attempted_at"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_checkin_id"], name: "index_cache_repair_tasks_on_client_checkin_id"
    t.index ["repair_key"], name: "index_cache_repair_tasks_on_repair_key"
    t.index ["scheduled_for"], name: "index_cache_repair_tasks_on_scheduled_for"
    t.index ["status"], name: "index_cache_repair_tasks_on_status"
    t.index ["user_id"], name: "index_cache_repair_tasks_on_user_id"
  end

  create_table "client_cache_metrics", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "client_checkin_id"
    t.string "metric_key", null: false
    t.bigint "hits_count", default: 0, null: false
    t.bigint "misses_count", default: 0, null: false
    t.bigint "refresh_count", default: 0, null: false
    t.bigint "bytes_sent", default: 0, null: false
    t.datetime "last_refreshed_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_checkin_id", "metric_key"], name: "index_cache_metrics_on_client_and_metric_key"
    t.index ["client_checkin_id"], name: "index_client_cache_metrics_on_client_checkin_id"
    t.index ["user_id", "metric_key"], name: "index_cache_metrics_on_user_and_metric_key"
    t.index ["user_id"], name: "index_client_cache_metrics_on_user_id"
  end

  create_table "client_cache_states", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "client_checkin_id", null: false
    t.string "state_key", null: false
    t.boolean "needs_refresh", default: true, null: false
    t.integer "version", default: 0, null: false
    t.string "context_reference"
    t.jsonb "context_data", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_checkin_id"], name: "index_client_cache_states_on_client_checkin_id"
    t.index ["state_key", "needs_refresh"], name: "index_cache_states_on_state_key_and_status"
    t.index ["user_id", "client_checkin_id", "state_key"], name: "index_cache_states_on_user_client_and_state_key", unique: true
    t.index ["user_id"], name: "index_client_cache_states_on_user_id"
  end

  create_table "client_checkins", force: :cascade do |t|
    t.bigint "user_id"
    t.string "client_id"
    t.string "client_type"
    t.datetime "last_ping_at"
    t.integer "cache_revision", default: 1, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "client_type"], name: "index_client_checkins_on_client_id_and_client_type", unique: true
    t.index ["user_id"], name: "index_client_checkins_on_user_id"
  end

  create_table "config_entries", force: :cascade do |t|
    t.string "key", null: false
    t.string "scope_type", default: "system", null: false
    t.bigint "scope_id"
    t.jsonb "value", default: {}, null: false
    t.string "context"
    t.text "description"
    t.boolean "locked", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key", "scope_type", "scope_id"], name: "index_config_entries_on_key_and_scope", unique: true
  end

  create_table "data_anomalies", force: :cascade do |t|
    t.string "detector_key", null: false
    t.string "record_type"
    t.bigint "record_id"
    t.string "severity", default: "warning", null: false
    t.string "status", default: "open", null: false
    t.jsonb "details", default: {}, null: false
    t.datetime "detected_at", null: false
    t.datetime "resolved_at"
    t.text "resolution_notes"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["detector_key"], name: "index_data_anomalies_on_detector_key"
    t.index ["record_type", "record_id"], name: "index_data_anomalies_on_record"
    t.index ["status"], name: "index_data_anomalies_on_status"
  end

  create_table "data_export_jobs", force: :cascade do |t|
    t.string "export_key", null: false
    t.string "status", default: "pending", null: false
    t.datetime "scheduled_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "range_start"
    t.datetime "range_end"
    t.string "destination", default: "s3", null: false
    t.jsonb "filters", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["export_key"], name: "index_data_export_jobs_on_export_key"
    t.index ["status"], name: "index_data_export_jobs_on_status"
  end

  create_table "data_export_payloads", force: :cascade do |t|
    t.bigint "data_export_job_id", null: false
    t.string "storage_location", null: false
    t.string "checksum"
    t.bigint "bytes", default: 0, null: false
    t.integer "record_count", default: 0, null: false
    t.datetime "available_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["available_at"], name: "index_data_export_payloads_on_available_at"
    t.index ["data_export_job_id"], name: "index_data_export_payloads_on_data_export_job_id"
  end

  create_table "data_transfer_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "client_checkin_id"
    t.string "transfer_key"
    t.string "direction", null: false
    t.bigint "bytes_transferred", null: false
    t.datetime "occurred_at", null: false
    t.date "bucket_date", null: false
    t.string "payload_type"
    t.string "request_route"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bucket_date"], name: "index_data_transfer_logs_on_bucket_date"
    t.index ["client_checkin_id", "transfer_key"], name: "index_transfer_logs_on_client_and_transfer_key"
    t.index ["client_checkin_id"], name: "index_data_transfer_logs_on_client_checkin_id"
    t.index ["user_id", "transfer_key"], name: "index_transfer_logs_on_user_and_transfer_key"
    t.index ["user_id"], name: "index_data_transfer_logs_on_user_id"
  end

  create_table "dependents", force: :cascade do |t|
    t.string "english_name", null: false
    t.string "native_name"
    t.string "national_id"
    t.date "birthdate"
    t.string "relationship_label"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dev_mode_tokens", force: :cascade do |t|
    t.bigint "admin_id", null: false
    t.string "token", null: false
    t.string "purpose"
    t.datetime "expires_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_dev_mode_tokens_on_admin_id"
    t.index ["token"], name: "index_dev_mode_tokens_on_token", unique: true
  end

  create_table "feature_flag_rollouts", force: :cascade do |t|
    t.bigint "config_entry_id", null: false
    t.boolean "enabled_by_default", default: true, null: false
    t.integer "rollout_percentage", default: 100, null: false
    t.string "prerequisite_key"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["config_entry_id"], name: "index_feature_flag_rollouts_on_config_entry_id"
    t.index ["prerequisite_key"], name: "index_feature_flag_rollouts_on_prerequisite_key"
  end

  create_table "financial_ledger_entries", force: :cascade do |t|
    t.bigint "user_id"
    t.string "entry_type", null: false
    t.string "currency", null: false
    t.string "country_code", default: "TW", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.decimal "tax_amount", precision: 15, scale: 2, default: "0.0", null: false
    t.string "status", default: "pending", null: false
    t.string "external_reference"
    t.date "entry_date", null: false
    t.string "user_name_snapshot"
    t.string "user_email_snapshot"
    t.jsonb "details", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_type", "entry_date"], name: "index_financial_entries_on_type_and_date"
    t.index ["external_reference"], name: "index_financial_ledger_entries_on_external_reference", unique: true
    t.index ["user_id"], name: "index_financial_ledger_entries_on_user_id"
  end

  create_table "line_pay_callbacks", force: :cascade do |t|
    t.bigint "temple_id", null: false
    t.string "line_pay_transaction_id", null: false
    t.string "event_type"
    t.jsonb "payload", default: {}, null: false
    t.boolean "processed", default: false, null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["temple_id", "line_pay_transaction_id"], name: "idx_line_pay_callbacks_on_transaction"
    t.index ["temple_id"], name: "index_line_pay_callbacks_on_temple_id"
  end

  create_table "media_assets", force: :cascade do |t|
    t.bigint "temple_id", null: false
    t.string "role", null: false
    t.string "file_uid", null: false
    t.string "alt_text"
    t.string "credit"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role"], name: "index_media_assets_on_role"
    t.index ["temple_id"], name: "index_media_assets_on_temple_id"
  end

  create_table "message_delivery_archives", force: :cascade do |t|
    t.bigint "user_id"
    t.string "channel", null: false
    t.string "recipient", null: false
    t.string "user_name_snapshot"
    t.string "recipient_name_snapshot"
    t.string "message_key"
    t.string "subject"
    t.jsonb "payload", default: {}, null: false
    t.string "status", default: "queued", null: false
    t.datetime "delivered_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel", "status"], name: "index_message_archives_on_channel_and_status"
    t.index ["message_key"], name: "index_message_delivery_archives_on_message_key"
    t.index ["user_id"], name: "index_message_delivery_archives_on_user_id"
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "channel", null: false
    t.boolean "enabled", default: true, null: false
    t.boolean "alert_sound_enabled", default: true, null: false
    t.boolean "silent_mode", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "channel"], name: "index_notification_preferences_on_user_id_and_channel", unique: true
    t.index ["user_id"], name: "index_notification_preferences_on_user_id"
  end

  create_table "notification_rules", force: :cascade do |t|
    t.string "event_key", null: false
    t.string "channel", null: false
    t.string "template_key"
    t.boolean "enabled", default: true, null: false
    t.integer "throttle_interval_seconds", default: 0, null: false
    t.integer "throttle_maximum", default: 0, null: false
    t.boolean "requires_opt_in", default: true, null: false
    t.jsonb "audience_filters", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_key", "channel"], name: "index_notification_rules_on_event_and_channel", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "notification_rule_id"
    t.bigint "user_id"
    t.string "channel", null: false
    t.string "status", default: "pending", null: false
    t.string "recipient"
    t.string "message_key"
    t.jsonb "payload", default: {}, null: false
    t.jsonb "delivery_context", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "scheduled_at"
    t.datetime "sent_at"
    t.datetime "failed_at"
    t.string "provider_message_id"
    t.text "error_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel", "recipient"], name: "index_notifications_on_channel_and_recipient"
    t.index ["notification_rule_id"], name: "index_notifications_on_notification_rule_id"
    t.index ["scheduled_at"], name: "index_notifications_on_scheduled_at"
    t.index ["status"], name: "index_notifications_on_status"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "oauth_identities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "provider_uid", null: false
    t.string "email"
    t.jsonb "credentials", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "provider_uid"], name: "index_oauth_identities_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_oauth_identities_on_user_id"
  end

  create_table "privacy_settings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "share_data_with_partners", default: false, null: false
    t.boolean "third_party_tracking_enabled", default: false, null: false
    t.boolean "email_tracking_opt_in", default: true, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_privacy_settings_on_user_id", unique: true
  end

  create_table "push_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "platform", null: false
    t.string "token", null: false
    t.string "device_name"
    t.datetime "last_seen_at"
    t.boolean "active", default: true, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "platform", "token"], name: "index_push_tokens_on_user_platform_token", unique: true
    t.index ["user_id"], name: "index_push_tokens_on_user_id"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.string "device_name"
    t.string "device_id"
    t.string "platform"
    t.datetime "expires_at", null: false
    t.datetime "last_used_at"
    t.boolean "revoked", default: false, null: false
    t.jsonb "privacy_flags", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_refresh_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "system_audit_logs", force: :cascade do |t|
    t.bigint "admin_id"
    t.bigint "user_id"
    t.string "action", null: false
    t.string "target_type"
    t.bigint "target_id"
    t.string "admin_name_snapshot"
    t.string "user_name_snapshot"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "temple_id"
    t.index ["admin_id"], name: "index_system_audit_logs_on_admin_id"
    t.index ["occurred_at"], name: "index_system_audit_logs_on_occurred_at"
    t.index ["target_type", "target_id"], name: "index_audit_logs_on_target"
    t.index ["temple_id"], name: "index_system_audit_logs_on_temple_id"
    t.index ["user_id"], name: "index_system_audit_logs_on_user_id"
  end

  create_table "temple_event_registrations", force: :cascade do |t|
    t.bigint "temple_id", null: false
    t.bigint "temple_offering_id"
    t.bigint "user_id"
    t.string "event_slug"
    t.string "reference_code", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "unit_price_cents", default: 0, null: false
    t.integer "total_price_cents", default: 0, null: false
    t.string "currency", default: "TWD", null: false
    t.jsonb "contact_payload", default: {}, null: false
    t.string "payment_status", default: "pending", null: false
    t.string "fulfillment_status", default: "open", null: false
    t.string "line_pay_transaction_id"
    t.string "certificate_number"
    t.jsonb "logistics_payload", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "fulfilled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["line_pay_transaction_id"], name: "index_temple_event_registrations_on_line_pay_transaction_id"
    t.index ["temple_id", "event_slug"], name: "index_temple_event_registrations_on_temple_id_and_event_slug"
    t.index ["temple_id", "payment_status"], name: "idx_event_registrations_on_payment_status"
    t.index ["temple_id", "reference_code"], name: "idx_event_registrations_on_code", unique: true
    t.index ["temple_id"], name: "index_temple_event_registrations_on_temple_id"
    t.index ["temple_offering_id"], name: "index_temple_event_registrations_on_temple_offering_id"
    t.index ["user_id"], name: "index_temple_event_registrations_on_user_id"
  end

  create_table "temple_gallery_entries", force: :cascade do |t|
    t.bigint "temple_id", null: false
    t.string "title", null: false
    t.text "body"
    t.datetime "event_date"
    t.jsonb "photo_urls", default: [], null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["temple_id", "event_date"], name: "index_gallery_entries_on_temple_and_event_date"
    t.index ["temple_id"], name: "index_temple_gallery_entries_on_temple_id"
  end

  create_table "temple_news_posts", force: :cascade do |t|
    t.bigint "temple_id", null: false
    t.string "title", null: false
    t.text "body"
    t.datetime "published_at"
    t.boolean "published", default: true, null: false
    t.boolean "pinned", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["temple_id", "published"], name: "index_news_posts_on_temple_and_status"
    t.index ["temple_id", "published_at"], name: "index_news_posts_on_temple_and_published_at"
    t.index ["temple_id"], name: "index_temple_news_posts_on_temple_id"
  end

  create_table "temple_offerings", force: :cascade do |t|
    t.bigint "temple_id", null: false
    t.string "slug", null: false
    t.string "offering_type", default: "general", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "price_cents", default: 0, null: false
    t.string "currency", default: "TWD", null: false
    t.string "period"
    t.date "starts_on"
    t.date "ends_on"
    t.integer "available_slots"
    t.boolean "active", default: true, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_temple_offerings_on_slug"
    t.index ["temple_id", "slug"], name: "index_temple_offerings_on_temple_id_and_slug", unique: true
    t.index ["temple_id"], name: "index_temple_offerings_on_temple_id"
  end

  create_table "temple_pages", force: :cascade do |t|
    t.bigint "temple_id", null: false
    t.string "kind", null: false
    t.string "title"
    t.string "slug"
    t.integer "position", default: 0, null: false
    t.jsonb "meta", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["temple_id", "kind"], name: "index_temple_pages_on_temple_id_and_kind", unique: true
    t.index ["temple_id", "slug"], name: "index_temple_pages_on_temple_id_and_slug"
    t.index ["temple_id"], name: "index_temple_pages_on_temple_id"
  end

  create_table "temple_payments", force: :cascade do |t|
    t.bigint "temple_id", null: false
    t.bigint "temple_event_registration_id", null: false
    t.bigint "user_id"
    t.bigint "financial_ledger_entry_id"
    t.bigint "admin_account_id"
    t.string "external_reference"
    t.string "payment_method", null: false
    t.string "status", default: "pending", null: false
    t.integer "amount_cents", default: 0, null: false
    t.string "currency", default: "TWD", null: false
    t.string "line_pay_transaction_id"
    t.jsonb "payment_payload", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_account_id"], name: "index_temple_payments_on_admin_account_id"
    t.index ["external_reference"], name: "index_temple_payments_on_external_reference", unique: true
    t.index ["financial_ledger_entry_id"], name: "index_temple_payments_on_financial_ledger_entry_id"
    t.index ["line_pay_transaction_id"], name: "index_temple_payments_on_line_pay_transaction_id"
    t.index ["payment_method"], name: "index_temple_payments_on_payment_method"
    t.index ["temple_event_registration_id"], name: "idx_temple_payments_on_registration"
    t.index ["temple_id", "status"], name: "index_temple_payments_on_temple_id_and_status"
    t.index ["temple_id"], name: "index_temple_payments_on_temple_id"
    t.index ["user_id"], name: "index_temple_payments_on_user_id"
  end

  create_table "temple_sections", force: :cascade do |t|
    t.bigint "temple_page_id", null: false
    t.string "section_type", null: false
    t.string "title"
    t.text "body"
    t.jsonb "payload", default: {}, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["temple_page_id"], name: "index_temple_sections_on_temple_page_id"
  end

  create_table "temples", force: :cascade do |t|
    t.string "slug", null: false
    t.string "name", null: false
    t.string "tagline"
    t.string "primary_image_url"
    t.text "hero_copy"
    t.text "about_html"
    t.jsonb "hero_images", default: {}, null: false
    t.jsonb "contact_info", default: {}, null: false
    t.jsonb "service_times", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.boolean "published", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_temples_on_slug", unique: true
  end

  create_table "usage_billing_snapshots", force: :cascade do |t|
    t.bigint "user_id"
    t.string "usage_type", null: false
    t.string "user_name_snapshot"
    t.bigint "quantity", default: 0, null: false
    t.bigint "bytes_consumed", default: 0, null: false
    t.integer "seats_active", default: 0, null: false
    t.date "bucket_date", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["usage_type", "bucket_date"], name: "index_usage_snapshots_on_type_and_bucket"
    t.index ["user_id"], name: "index_usage_billing_snapshots_on_user_id"
  end

  create_table "user_dependents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "dependent_id", null: false
    t.string "role", default: "caretaker", null: false
    t.string "relationship_label"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dependent_id"], name: "index_user_dependents_on_dependent_id"
    t.index ["user_id", "dependent_id"], name: "index_user_dependents_on_user_and_dependent", unique: true
    t.index ["user_id"], name: "index_user_dependents_on_user_id"
  end

  create_table "user_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "locale", default: "en", null: false
    t.string "timezone", default: "UTC", null: false
    t.string "currency", default: "USD", null: false
    t.string "theme", default: "light", null: false
    t.string "temperature_unit", default: "F", null: false
    t.string "measurement_system", default: "imperial", null: false
    t.boolean "twenty_four_hour_time", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_preferences_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "english_name", null: false
    t.string "native_name"
    t.string "national_id"
    t.date "birthdate"
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "account_lifecycle_events", "users"
  add_foreign_key "admin_permissions", "admins", column: "admin_account_id"
  add_foreign_key "admin_permissions", "temples"
  add_foreign_key "admin_temple_memberships", "admins", column: "admin_account_id"
  add_foreign_key "admin_temple_memberships", "temples"
  add_foreign_key "admins", "users"
  add_foreign_key "agreement_acceptances", "agreements"
  add_foreign_key "agreement_acceptances", "users"
  add_foreign_key "api_usage_logs", "users"
  add_foreign_key "cache_repair_tasks", "client_checkins"
  add_foreign_key "cache_repair_tasks", "users"
  add_foreign_key "client_cache_metrics", "client_checkins"
  add_foreign_key "client_cache_metrics", "users"
  add_foreign_key "client_cache_states", "client_checkins"
  add_foreign_key "client_cache_states", "users"
  add_foreign_key "client_checkins", "users"
  add_foreign_key "data_export_payloads", "data_export_jobs"
  add_foreign_key "data_transfer_logs", "client_checkins"
  add_foreign_key "data_transfer_logs", "users"
  add_foreign_key "dev_mode_tokens", "admins"
  add_foreign_key "feature_flag_rollouts", "config_entries"
  add_foreign_key "financial_ledger_entries", "users"
  add_foreign_key "line_pay_callbacks", "temples"
  add_foreign_key "media_assets", "temples"
  add_foreign_key "message_delivery_archives", "users"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "notifications", "notification_rules"
  add_foreign_key "notifications", "users"
  add_foreign_key "oauth_identities", "users"
  add_foreign_key "privacy_settings", "users"
  add_foreign_key "push_tokens", "users"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "system_audit_logs", "admins"
  add_foreign_key "system_audit_logs", "temples"
  add_foreign_key "system_audit_logs", "users"
  add_foreign_key "temple_event_registrations", "temple_offerings"
  add_foreign_key "temple_event_registrations", "temples"
  add_foreign_key "temple_event_registrations", "users"
  add_foreign_key "temple_gallery_entries", "temples"
  add_foreign_key "temple_news_posts", "temples"
  add_foreign_key "temple_offerings", "temples"
  add_foreign_key "temple_pages", "temples"
  add_foreign_key "temple_payments", "admins", column: "admin_account_id"
  add_foreign_key "temple_payments", "financial_ledger_entries"
  add_foreign_key "temple_payments", "temple_event_registrations"
  add_foreign_key "temple_payments", "temples"
  add_foreign_key "temple_payments", "users"
  add_foreign_key "temple_sections", "temple_pages"
  add_foreign_key "usage_billing_snapshots", "users"
  add_foreign_key "user_dependents", "dependents"
  add_foreign_key "user_dependents", "users"
  add_foreign_key "user_preferences", "users"
end
