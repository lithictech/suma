# frozen_string_literal: true

require "sequel/all_or_none_constraint"
require "sequel/unambiguous_constraint"

Sequel.migration do
  up do
    alter_table(:mobility_trips) do
      add_column :vehicle_type, :text
    end
    from(:mobility_trips).update(vehicle_type: "ebike")
    alter_table(:mobility_trips) do
      set_column_not_null :vehicle_type
    end
  end
  down do
    alter_table(:mobility_trips) do
      drop_column :vehicle_type
    end
  end
end
