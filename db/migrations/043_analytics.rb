# frozen_string_literal: true

Sequel.migration do
  up do
    create_schema(:analytics, if_not_exists: true)

    create_table(Sequel[:analytics][:members]) do
      primary_key :pk
      integer :member_id, unique: true, null: false

      timestamptz :created_at
      timestamptz :soft_deleted_at
      text :email
      text :phone
      text :name
      text :timezone

      integer :order_count
    end

    create_table(Sequel[:analytics][:orders]) do
      primary_key :pk
      integer :order_id, unique: true, null: false

      timestamptz :created_at
      text :order_status
      text :fulfillment_status

      integer :member_id

      decimal :undiscounted_cost
      decimal :customer_cost
      decimal :savings
      decimal :handling
      decimal :taxable_cost
      decimal :tax
      decimal :total

      decimal :funded_cost
      decimal :paid_cost
      decimal :cash_paid
      decimal :noncash_paid
    end

    create_table(Sequel[:analytics][:order_items]) do
      primary_key :pk
      integer :checkout_item_id, unique: true, null: false

      timestamptz :created_at
      integer :order_id
      integer :member_id

      decimal :undiscounted_cost
      decimal :customer_cost
      decimal :savings
    end

    create_table(Sequel[:analytics][:ledgers]) do
      primary_key :pk
      integer :ledger_id, unique: true, null: false

      integer :payment_account_id
      integer :member_id
      text :name

      decimal :balance
      decimal :total_credits
      decimal :total_debits
    end
  end

  down do
    drop_table(Sequel[:analytics][:members])
    drop_table(Sequel[:analytics][:orders])
    drop_table(Sequel[:analytics][:order_items])
    drop_table(Sequel[:analytics][:ledgers])
  end
end
