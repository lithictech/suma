# frozen_string_literal: true

Sequel.migration do
  up do
    run "CREATE EXTENSION IF NOT EXISTS vector"
    alter_table(:members) do
      add_column :embedding, "vector(384)"
      add_column :embedding_hash, :text
    end
  end
  down do
    alter_table(:members) do
      drop_column :embedding
      drop_column :embedding_hash
    end
  end
end
