# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:commerce_products) do
      add_column :max_quantity_per_order, :integer, null: true
      add_constraint(
        :positive_quantity_per_order,
        Sequel[max_quantity_per_order: nil] | Sequel.expr { max_quantity_per_order > 0 },
      )
      add_column :max_quantity_per_offering, :integer, null: true
      add_constraint(
        :positive_quantity_per_offering,
        Sequel[max_quantity_per_offering: nil] | Sequel.expr { max_quantity_per_offering > 0 },
      )
    end
  end
end
