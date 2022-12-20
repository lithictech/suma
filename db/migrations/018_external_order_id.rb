# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:commerce_orders) do
      add_column :external_id, :text, null: false, default: ""
    end
  end
end
