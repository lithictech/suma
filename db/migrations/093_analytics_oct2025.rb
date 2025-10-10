# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(Sequel[:analytics][:members]) do
      add_column :roles, "text[]"
    end

    create_table(Sequel[:analytics][:trips]) do
      primary_key :pk
      integer :trip_id, unique: true, null: false
      timestamptz :created_at

      integer :member_id
      integer :vendor_service_id
      text :vendor_service_name
      integer :vendor_id
      text :vendor_name
      integer :vendor_service_rate_id
      text :vendor_service_rate_name

      timestamptz :began_at
      numeric :begin_lat
      numeric :begin_lng
      timestamptz :ended_at
      numeric :end_lat
      numeric :end_lng

      decimal :undiscounted_cost
      decimal :customer_cost
      decimal :savings
      decimal :total

      decimal :funded_cost
      decimal :paid_cost
      decimal :cash_paid
      decimal :noncash_paid
    end
  end
end
