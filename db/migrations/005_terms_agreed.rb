# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:members) do
      add_column :terms_agreed, :date
    end
  end
end
