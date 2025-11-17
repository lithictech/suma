# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:payment_triggers) do
      add_column :act_as_credit, :boolean, default: false, null: false
    end
  end
end
