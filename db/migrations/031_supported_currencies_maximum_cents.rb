# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:supported_currencies) do
      add_column :funding_maximum_cents, :integer, null: true
    end
    from(:supported_currencies).update(funding_maximum_cents: 100_00)
    alter_table(:supported_currencies) do
      set_column_not_null :funding_maximum_cents
    end
  end
end
