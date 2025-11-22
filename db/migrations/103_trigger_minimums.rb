# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:payment_triggers) do
      add_column :unmatched_amount_cents, :integer, default: 0, null: false
    end
  end
end
