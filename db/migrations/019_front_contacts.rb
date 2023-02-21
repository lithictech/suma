# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:members) do
      add_column :front_contact_id, :text, null: false, default: ""
    end
  end
end
