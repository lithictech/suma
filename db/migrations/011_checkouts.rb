# frozen_string_literal: true

require "sequel/unambiguous_constraint"
require "sequel/nonempty_string_constraint"

Sequel.migration do
  up do
    # We are redoing these in this migration
    drop_table(:commerce_checkouts)
    drop_table(:commerce_fulfillment_options)

    alter_table(:commerce_carts) do
      drop_index([:member_id, :offering_id])
      drop_column :soft_deleted_at
      add_index [:member_id, :offering_id], unique: true
    end

    create_table(:commerce_offering_fulfillment_options) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      timestamptz :soft_deleted_at

      text :type, null: false
      float :ordinal, null: false, default: 0

      foreign_key :description_id, :translated_texts, null: false
      foreign_key :address_id, :addresses

      foreign_key :offering_id, :commerce_offerings, null: false
      index :offering_id
    end

    create_table(:commerce_checkouts) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      timestamptz :soft_deleted_at
      timestamptz :completed_at

      foreign_key :cart_id, :commerce_carts, null: false
      index :cart_id, unique: true, where: Sequel[completed_at: nil, soft_deleted_at: nil]

      foreign_key :bank_account_id, :payment_bank_accounts
      foreign_key :card_id, :payment_cards
      constraint(
        :unambiguous_payment_instrument,
        Sequel.unambiguous_constraint([:bank_account_id, :card_id], allow_all_null: true),
      )

      boolean :save_payment_instrument, null: false, default: false

      foreign_key :fulfillment_option_id, :commerce_offering_fulfillment_options, null: false
    end

    create_table(:commerce_checkout_items) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)

      foreign_key :offering_product_id, :commerce_offering_products, null: false
      foreign_key :checkout_id, :commerce_checkouts, null: false, on_delete: :cascade
      foreign_key :cart_item_id, :commerce_cart_items, null: true
      integer :immutable_quantity, null: true

      index [:checkout_id, :cart_item_id], unique: true
      index [:checkout_id, :offering_product_id], unique: true
      constraint(:unambiguous_quantity, Sequel.unambiguous_constraint([:cart_item_id, :immutable_quantity]))
    end

    create_table(:commerce_orders) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :order_status, null: false
      text :fulfillment_status, null: false

      foreign_key :checkout_id, :commerce_checkouts, null: false, unique: true
    end

    create_table(:commerce_order_audit_logs) do
      primary_key :id
      timestamptz :at, null: false

      text :event, null: false
      text :to_state, null: false
      text :from_state, null: false
      text :reason, null: false, default: ""
      jsonb :messages, null: false, default: "[]"

      foreign_key :order_id, :commerce_orders, null: false
      foreign_key :actor_id, :members, on_delete: :set_null
    end
  end

  down do
    drop_table(:commerce_order_audit_logs)
    drop_table(:commerce_orders)
    drop_table(:commerce_checkout_items)
    drop_table(:commerce_checkouts)
    drop_table(:commerce_offering_fulfillment_options)
    create_table(:commerce_fulfillment_options) do
      primary_key :id
    end
    create_table(:commerce_checkouts) do
      primary_key :id
    end
    alter_table(:commerce_carts) do
      add_column :soft_deleted_at, :timestamptz
      drop_index([:member_id, :offering_id])
      add_index [:member_id, :offering_id], unique: true
    end
  end
end
