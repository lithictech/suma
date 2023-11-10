# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:vendors) do
      add_index :slug, unique: true
    end

    alter_table(:eligibility_constraints) do
      add_index :name, unique: true
    end
  end
end
