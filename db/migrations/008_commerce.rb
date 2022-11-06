# frozen_string_literal: true

require "sequel/unambiguous_constraint"

Sequel.migration do
  change do
    create_table(:commerce_products) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :name, null: false
      text :description, null: false, default: ""

      foreign_key :vendor_id, :vendors, null: false
      int :our_cost_cents, null: false
      text :our_cost_currency, null: false
    end

    create_table(:commerce_offerings) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      tstzrange :period, null: false
      text :description, null: false
    end

    create_table(:commerce_offering_products) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      timestamptz :closed_at

      foreign_key :product_id, :commerce_products, null: false
      index :product_id
      foreign_key :offering_id, :commerce_offerings, null: false
      index :offering_id

      index [:product_id, :offering_id], unique: true, where: Sequel[closed_at: nil]

      int :customer_price_cents, null: false
      text :customer_price_currency, null: false
      int :undiscounted_price_cents, null: false
      text :undiscounted_price_currency, null: false
    end

    create_table(:images) do
      primary_key :id

      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      timestamptz :soft_deleted_at

      float :ordinal, null: false, default: 0
      text :caption, null: false, default: ""

      foreign_key :uploaded_file_id, :uploaded_files, null: false

      foreign_key :commerce_product_id, :commerce_products
      index :commerce_product_id
      foreign_key :commerce_offering_id, :commerce_offerings
      index :commerce_offering_id
      constraint(
        :unambiguous_relation,
        Sequel.unambiguous_constraint([:commerce_product_id, :commerce_offering_id]),
      )
    end
  end
end
