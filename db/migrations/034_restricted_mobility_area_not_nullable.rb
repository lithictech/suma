# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:mobility_restricted_areas) do
      set_column_not_null :restriction
    end
  end
end
