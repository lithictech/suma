# frozen_string_literal: true

Sequel.migration do
  up do
    run "CREATE EXTENSION IF NOT EXISTS vector"
    alter_table(:members) do
      add_column :search_content, :text
      add_column :search_embedding, "vector(384)"
      add_column :search_hash, :text
      add_index Sequel.function(:to_tsvector, "english", :search_content),
                name: :search_content_tsvector_index,
                using: :gin
    end
  end
  down do
    alter_table(:members) do
      drop_column :search_content
      drop_column :search_embedding
      drop_column :search_hash
      drop_column :search_tsvector
    end
  end
end
