# frozen_string_literal: true

class CreateTempleFinancialTables < ActiveRecord::Migration[7.1]
  def change
    create_table :temple_offerings do |t|
      t.references :temple, null: false, foreign_key: true
      t.string :slug, null: false
      t.string :offering_type, null: false, default: "general"
      t.string :title, null: false
      t.text :description
      t.integer :price_cents, null: false, default: 0
      t.string :currency, null: false, default: "TWD"
      t.string :period
      t.date :starts_on
      t.date :ends_on
      t.integer :available_slots
      t.boolean :active, null: false, default: true
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :temple_offerings, [:temple_id, :slug], unique: true
    add_index :temple_offerings, :slug

    create_table :temple_event_registrations do |t|
      t.references :temple, null: false, foreign_key: true
      t.references :temple_offering, foreign_key: true
      t.references :user, foreign_key: true
      t.string :event_slug
      t.string :reference_code, null: false
      t.integer :quantity, null: false, default: 1
      t.integer :unit_price_cents, null: false, default: 0
      t.integer :total_price_cents, null: false, default: 0
      t.string :currency, null: false, default: "TWD"
      t.jsonb :contact_payload, null: false, default: {}
      t.string :payment_status, null: false, default: "pending"
      t.string :fulfillment_status, null: false, default: "open"
      t.string :line_pay_transaction_id
      t.string :certificate_number
      t.jsonb :logistics_payload, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.datetime :fulfilled_at
      t.timestamps
    end
    add_index :temple_event_registrations, [:temple_id, :reference_code], unique: true, name: "idx_event_registrations_on_code"
    add_index :temple_event_registrations, [:temple_id, :payment_status], name: "idx_event_registrations_on_payment_status"
    add_index :temple_event_registrations, :line_pay_transaction_id
    add_index :temple_event_registrations, [:temple_id, :event_slug]

    create_table :temple_payments do |t|
      t.references :temple, null: false, foreign_key: true
      t.references :temple_event_registration, null: false, foreign_key: true, index: { name: "idx_temple_payments_on_registration" }
      t.references :user, foreign_key: true
      t.references :financial_ledger_entry, foreign_key: true
      t.references :admin_account, foreign_key: { to_table: :admins }
      t.string :external_reference
      t.string :payment_method, null: false
      t.string :status, null: false, default: "pending"
      t.integer :amount_cents, null: false, default: 0
      t.string :currency, null: false, default: "TWD"
      t.string :line_pay_transaction_id
      t.jsonb :payment_payload, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.datetime :processed_at
      t.timestamps
    end
    add_index :temple_payments, [:temple_id, :status]
    add_index :temple_payments, :payment_method
    add_index :temple_payments, :external_reference, unique: true
    add_index :temple_payments, :line_pay_transaction_id

    create_table :line_pay_callbacks do |t|
      t.references :temple, null: false, foreign_key: true
      t.string :line_pay_transaction_id, null: false
      t.string :event_type
      t.jsonb :payload, null: false, default: {}
      t.boolean :processed, null: false, default: false
      t.datetime :processed_at
      t.timestamps
    end
    add_index :line_pay_callbacks, [:temple_id, :line_pay_transaction_id], name: "idx_line_pay_callbacks_on_transaction"
  end
end
