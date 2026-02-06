# frozen_string_literal: true

class CreateTempleFinancialTables < ActiveRecord::Migration[7.1]
  def change
    create_table :temple_events do |t|
      t.references :temple, null: false, foreign_key: true
      t.string :slug, null: false
      t.string :title, null: false
      t.string :subtitle
      t.text :description
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.time :start_time
      t.time :end_time
      t.string :location_name
      t.string :location_address
      t.text :location_notes
      t.integer :capacity_total
      t.integer :capacity_reserved
      t.integer :capacity_remaining
      t.string :status, null: false, default: "draft"
      t.integer :price_cents, null: false, default: 0
      t.string :currency, null: false, default: "TWD"
      t.string :hero_image_url
      t.string :poster_image_url
      t.jsonb :logic_flags, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :temple_events, [:temple_id, :slug], unique: true
    add_index :temple_events, [:temple_id, :status]
    add_index :temple_events, [:temple_id, :starts_on]

    create_table :temple_services do |t|
      t.references :temple, null: false, foreign_key: true
      t.string :slug, null: false
      t.string :title, null: false
      t.string :subtitle
      t.text :description
      t.string :period_label
      t.date :available_from
      t.date :available_until
      t.integer :quantity_limit
      t.string :default_location
      t.text :fulfillment_notes
      t.string :status, null: false, default: "draft"
      t.integer :price_cents, null: false, default: 0
      t.string :currency, null: false, default: "TWD"
      t.string :hero_image_url
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :temple_services, [:temple_id, :slug], unique: true
    add_index :temple_services, [:temple_id, :status]
    add_index :temple_services, [:temple_id, :available_from], name: "index_temple_services_on_temple_and_available_from"

    create_table :temple_gatherings do |t|
      t.references :temple, null: false, foreign_key: true
      t.string :slug, null: false
      t.string :title, null: false
      t.string :subtitle
      t.text :description
      t.date :starts_on
      t.date :ends_on
      t.time :start_time
      t.time :end_time
      t.string :location_name
      t.string :location_address
      t.text :location_notes
      t.string :status, null: false, default: "draft"
      t.integer :price_cents, null: false, default: 0
      t.string :currency, null: false, default: "TWD"
      t.string :hero_image_url
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :temple_gatherings, [:temple_id, :slug], unique: true
    add_index :temple_gatherings, [:temple_id, :status]

    create_table :temple_registrations do |t|
      t.references :temple, null: false, foreign_key: true
      t.references :registrable, polymorphic: true, null: false
      t.references :user, foreign_key: true
      t.string :reference_code, null: false
      t.integer :quantity, null: false, default: 1
      t.integer :unit_price_cents, null: false, default: 0
      t.integer :total_price_cents, null: false, default: 0
      t.string :currency, null: false, default: "TWD"
      t.jsonb :contact_payload, null: false, default: {}
      t.jsonb :logistics_payload, null: false, default: {}
      t.jsonb :ritual_payload, null: false, default: {}
      t.string :payment_status, null: false, default: "pending"
      t.string :fulfillment_status, null: false, default: "open"
      t.datetime :fulfilled_at
      t.datetime :cancelled_at
      t.text :notes
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :temple_registrations, [:temple_id, :reference_code], unique: true, name: "idx_temple_registrations_on_code"
    add_index :temple_registrations, [:temple_id, :payment_status], name: "idx_temple_registrations_on_payment_status"
    add_index :temple_registrations, [:temple_id, :fulfillment_status], name: "idx_temple_registrations_on_fulfillment_status"

    create_table :temple_payments do |t|
      t.references :temple, null: false, foreign_key: true
      t.references :temple_registration, null: false, foreign_key: true, index: { name: "idx_payments_on_registration" }
      t.references :user, foreign_key: true
      t.references :admin_account, foreign_key: { to_table: :admins }
      t.string :provider, null: false
      t.string :provider_account, null: false, default: "temple"
      t.string :provider_reference
      t.string :external_reference
      t.string :payment_method, null: false
      t.string :status, null: false, default: "pending"
      t.integer :amount_cents, null: false, default: 0
      t.string :currency, null: false, default: "TWD"
      t.jsonb :payment_payload, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.datetime :processed_at
      t.datetime :refunded_at
      t.timestamps
    end
    add_index :temple_payments, [:temple_id, :status]
    add_index :temple_payments, [:temple_id, :provider]
    add_index :temple_payments, :provider_reference
    add_index :temple_payments, :external_reference, unique: true

    create_table :payment_webhook_logs do |t|
      t.references :temple, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :event_type, null: false
      t.string :provider_reference, null: false
      t.jsonb :payload, null: false, default: {}
      t.boolean :processed, null: false, default: false
      t.datetime :processed_at
      t.timestamps
    end
    add_index :payment_webhook_logs, [:temple_id, :provider_reference], name: "idx_payment_webhooks_on_reference"
  end
end
