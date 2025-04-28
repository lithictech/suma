# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:organizations) do
      add_column :ordinal, :float, null: false, default: 0
    end
  end
end
