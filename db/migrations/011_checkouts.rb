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

      text :description
      foreign_key :address_id, :addresses
      constraint(
        :description_set_if_no_address,
        Sequel.nonempty_string_constraint(:description) | (Sequel[:address_id] !~ nil),
      )

      foreign_key :offering_id, :commerce_offerings, null: false
      index :offering_id
    end

    create_table(:commerce_checkouts) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      timestamptz :soft_deleted_at
      timestamptz :completed_at

      foreign_key :member_id, :members, null: false

      index [:member_id, :completed_at], unique: true, where: Sequel[completed_at: nil]

      foreign_key :bank_account_id, :payment_bank_accounts
      foreign_key :card_id, :payment_cards
      constraint(
        :unambiguous_payment_instrument,
        Sequel.unambiguous_constraint([:bank_account_id, :card_id], allow_all_null: true),
      )

      foreign_key :fulfillment_option_id, :commerce_offering_fulfillment_options, null: false
    end

    create_table(:commerce_checkout_items) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)

      foreign_key :checkout_id, :commerce_checkouts, null: false
      foreign_key :offering_product_id, :commerce_offering_products, null: false
      index [:checkout_id, :offering_product_id], unique: true

      integer :quantity, null: false
      constraint(:positive_quantity, Sequel[:quantity] > 0)
    end
  end

  down do
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
