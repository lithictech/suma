# frozen_string_literal: true

Sequel.migration do
  up do
    # When the Lyft Pass sync code was shipped, we could create duplicate charges
    # that ended up not being linked to a charge or order. It was fixed on May 5, 2025.
    # This condition should not exist otherwise: there must always be something
    # a charge is associated with (though it can be multiple things).
    from(:charges).where(commerce_order_id: nil, mobility_trip_id: nil).delete
    alter_table(:charges) do
      add_constraint(
        :associated_object_set,
        (Sequel[:commerce_order_id] !~ nil) | (Sequel[:mobility_trip_id] !~ nil),
      )
      # Drop the original indices for ones that now enforce uniqueness
      drop_index :commerce_order_id
      drop_index :mobility_trip_id
      # Enforce uniqueness across rows that have values
      add_index :commerce_order_id, unique: true, where: Sequel[:commerce_order_id] !~ nil
      add_index :mobility_trip_id, unique: true, where: Sequel[:mobility_trip_id] !~ nil
    end
  end
  down do
    alter_table(:charges) do
      drop_constraint(:associated_object_set)
      drop_index :commerce_order_id
      drop_index :mobility_trip_id
      add_index :commerce_order_id
      add_index :mobility_trip_id
    end
  end
end
