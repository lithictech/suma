# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:mobility_vehicles) do
      add_column :lat_int, Integer
      add_column :lng_int, Integer
    end
    from(:mobility_vehicles).update(
      lat_int: (Sequel[:lat] * 10_000_000).cast(:int),
      lng_int: (Sequel[:lng] * 10_000_000).cast(:int),
    )
    alter_table(:mobility_vehicles) do
      set_column_not_null :lat_int
      set_column_not_null :lng_int
    end
  end

  down do
    alter_table(:mobility_vehicles) do
      drop_column :lat_int
      drop_column :lng_int
    end
  end
end
