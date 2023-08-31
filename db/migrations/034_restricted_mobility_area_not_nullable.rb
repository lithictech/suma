# frozen_string_literal: true

Sequel.migration do
  up do
    from(:mobility_restricted_areas).where(restriction: nil).delete
    alter_table(:mobility_restricted_areas) do
      set_column_not_null :restriction
    end
  end

  down do
    alter_table(:mobility_restricted_areas) do
      set_column_allow_null :restriction
    end
  end
end
