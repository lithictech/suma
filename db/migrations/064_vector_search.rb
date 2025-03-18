# frozen_string_literal: true

Sequel.migration do
  up do
    run "CREATE EXTENSION IF NOT EXISTS vector"
    alter_table(:members) do
      add_column :embeddings, "vector(384)"
      add_column :embeddings_hash, :text
    end
  end
  down do
    alter_table(:members) do
      drop_column :embeddings
      drop_column :embeddings_hash
    end
  end
end
