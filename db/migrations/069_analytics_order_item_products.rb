# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(Sequel[:analytics][:order_items]) do
      add_column :quantity, :integer
      add_column :product_id, :integer
      add_column :product_name, :text
      add_column :vendor_id, :integer
      add_column :vendor_name, :text
      add_column :offering_id, :integer
      add_column :offering_name, :text
      add_column :offering_begin, :timestamptz
      add_column :offering_end, :timestamptz
    end
  end
end
