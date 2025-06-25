# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:payment_ledgers) do
      set_column_not_null :account_id
    end
  end
end
