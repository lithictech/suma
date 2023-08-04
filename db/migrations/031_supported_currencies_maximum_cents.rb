# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:supported_currencies) do
      add_column :funding_maximum_cents, :integer, null: false
    end
  end
end
