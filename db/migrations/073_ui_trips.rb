# frozen_string_literal: true

require "sequel/all_or_none_constraint"
require "sequel/unambiguous_constraint"

Sequel.migration do
  up do
    alter_table(:uploaded_files) do
      add_column :private, :boolean, default: false, null: false
    end

    alter_table(:images) do
      add_foreign_key :mobility_trip_id, :mobility_trips, null: true, index: true
      drop_constraint(:unambiguous_relation)
      add_constraint(
        :unambiguous_relation,
        Sequel.unambiguous_constraint(
          [
            :commerce_product_id,
            :commerce_offering_id,
            :vendor_id,
            :vendor_service_id,
            :program_id,
            :mobility_trip_id,
          ],
        ),
      )
    end

    alter_table(:mobility_trips) do
      add_column :vehicle_type, :text
      add_column :begin_address, :text
      add_column :end_address, :text
    end
    from(:mobility_trips).update(vehicle_type: "ebike")
    alter_table(:mobility_trips) do
      set_column_not_null :vehicle_type
    end
  end

  down do
    alter_table(:uploaded_files) do
      drop_column :private
    end
    alter_table(:images) do
      drop_constraint(:unambiguous_relation)
      add_constraint(
        :unambiguous_relation,
        Sequel.unambiguous_constraint(
          [
            :commerce_product_id,
            :commerce_offering_id,
            :vendor_id,
            :vendor_service_id,
            :program_id,
          ],
        ),
      )
      drop_column :mobility_trip_id
    end
    alter_table(:mobility_trips) do
      drop_column :vehicle_type
      drop_column :begin_address
      drop_column :end_address
    end
  end
end
