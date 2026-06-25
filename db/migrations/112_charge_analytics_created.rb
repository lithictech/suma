# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(Sequel[:analytics][:charges]) do
      add_column :incurred_at, :timestamptz
    end
  end
end
