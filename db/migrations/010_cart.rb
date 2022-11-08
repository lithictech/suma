# frozen_string_literal: true

require "sequel/unambiguous_constraint"
require "sequel/nonempty_string_constraint"

Sequel.migration do
  change do
    create_table(:commerce_carts) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      timestamptz :soft_deleted_at
      foreign_key :member_id, :members, null: false
      foreign_key :offering_id, :commerce_offerings, null: false
      index [:member_id, :offering_id], unique: true, where: Sequel[soft_deleted_at: nil]
    end

    create_table(:commerce_cart_items) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :cart_id, :commerce_carts, null: false
      foreign_key :product_id, :commerce_products, null: false
      index [:cart_id, :product_id], unique: true

      integer :quantity, null: false
      constraint(:positive_quantity, Sequel[:quantity] > 0)

      decimal :timestamp, null: false
    end

    create_table(:commerce_fulfillment_options) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      timestamptz :soft_deleted_at

      text :type, null: false

      text :description
      foreign_key :address_id, :addresses
      constraint(
        :description_set_if_no_address,
        Sequel.nonempty_string_constraint(:description) | (Sequel[:address_id] !~ nil),
      )
    end

    create_table(:commerce_checkouts) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      timestamptz :soft_deleted_at

      foreign_key :cart_id, :commerce_carts, null: false
      index :cart_id

      foreign_key :bank_account_id, :payment_bank_accounts
      foreign_key :card_id, :payment_cards
      constraint(:unambiguous_payment_instrument, Sequel.unambiguous_constraint([:bank_account_id, :card_id]))

      foreign_key :fulfillment_option_id, :commerce_fulfillment_options
    end
  end
end
