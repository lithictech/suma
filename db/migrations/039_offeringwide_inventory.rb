# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:commerce_offerings) do
      add_column :max_ordered_items_cumulative, :integer
      add_column :max_ordered_items_per_member, :integer
    end

    alter_table(:commerce_product_inventories) do
      rename_column :max_quantity_per_order, :max_quantity_per_member_per_offering
      drop_column :max_quantity_per_offering
    end
  end

  down do
    alter_table(:commerce_product_inventories) do
      rename_column :max_quantity_per_member_per_offering, :max_quantity_per_order
      add_column :max_quantity_per_offering, :integer
    end

    alter_table(:commerce_offerings) do
      drop_column :max_ordered_items_cumulative
      drop_column :max_ordered_items_per_member
    end
  end
end
