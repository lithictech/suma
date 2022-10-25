# frozen_string_literal: true

Sequel.migration do
  change do
    rename_table(:bank_accounts, :payment_bank_accounts)
  end
end
