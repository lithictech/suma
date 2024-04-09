# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:commerce_checkouts) do
      set_column_allow_null :fulfillment_option_id
    end
  end
end
