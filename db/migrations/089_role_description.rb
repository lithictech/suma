# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:roles) do
      add_column :description, :text, null: false, default: ""
    end
  end
end
