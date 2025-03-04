# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:members) do
      drop_column :frontapp_contact_id
    end
  end

  down do
    alter_table(:members) do
      add_column :frontapp_contact_id, :text, null: false, default: ""
    end
  end
end
