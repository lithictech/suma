# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:commerce_product_inventories) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :product_id, :commerce_products, null: false, unique: true

      integer :max_quantity_per_order, null: true
      constraint(
        :positive_quantity_per_order,
        Sequel[max_quantity_per_order: nil] | Sequel.expr { max_quantity_per_order > 0 },
      )
      integer :max_quantity_per_offering, null: true
      constraint(
        :positive_quantity_per_offering,
        Sequel[max_quantity_per_offering: nil] | Sequel.expr { max_quantity_per_offering > 0 },
      )
      boolean :limited_quantity, null: false, default: false
      integer :quantity_on_hand, null: false, default: 0
    end
    from(:commerce_products).each do |row|
      from(:commerce_product_inventories).insert(
        product_id: row[:id],
        max_quantity_per_order: row[:max_quantity_per_order],
        max_quantity_per_offering: row[:max_quantity_per_offering],
      )
    end
    alter_table(:commerce_products) do
      drop_column :max_quantity_per_order
      drop_column :max_quantity_per_offering
    end
  end

  down do
    alter_table(:commerce_products) do
      add_column :max_quantity_per_order, :integer, null: true
      add_column :max_quantity_per_offering, :integer, null: true
    end
    from(:commerce_product_inventories).each do |row|
      from(:commerce_products).where(id: row[:product_id]).update(
        max_quantity_per_order: row[:max_quantity_per_order],
        max_quantity_per_offering: row[:max_quantity_per_offering],
      )
    end
    drop_table(:commerce_product_inventories)
  end
end
