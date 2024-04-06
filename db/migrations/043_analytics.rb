# frozen_string_literal: true

Sequel.migration do
  up do
    create_schema(:analytics, if_not_exists: true)

    create_table(Sequel[:analytics][:members]) do
      primary_key :pk
      integer :member_id, unique: true, null: false

      timestamptz :created_at
      timestamptz :updated_at
      timestamptz :soft_deleted_at
      citext :email
      text :phone
      text :name
      text :timezone

      integer :order_count
    end

    create_table(Sequel[:analytics][:orders]) do
      primary_key :pk
      integer :order_id, unique: true, null: false

      timestamptz :created_at
      timestamptz :updated_at
      timestamptz :soft_deleted_at
      integer :member_id

      decimal :funded_amount
      decimal :paid_amount
    end
  end
  down do
    drop_table(Sequel[:analytics][:members])
    drop_table(Sequel[:analytics][:orders])
  end
end
