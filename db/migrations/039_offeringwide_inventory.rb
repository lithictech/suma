# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:commerce_offerings) do
      add_column :max_ordered_items_cumulative, :integer
      add_column :max_ordered_items_per_member, :integer
    end

    alter_table(:commerce_offering_products) do
      add_column :max_quantity_per_member, :integer
    end

    alter_table(:commerce_product_inventories) do
      drop_column :max_quantity_per_order
      drop_column :max_quantity_per_offering
    end
  end

  down do
    alter_table(:commerce_product_inventories) do
      add_column :max_quantity_per_order, :integer
      add_column :max_quantity_per_offering, :integer
    end

    alter_table(:commerce_offering_products) do
      drop_column :max_quantity_per_member
    end

    alter_table(:commerce_offerings) do
      drop_column :max_ordered_items_cumulative
      drop_column :max_ordered_items_per_member
    end
  end
end
