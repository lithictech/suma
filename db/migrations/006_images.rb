# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:uploaded_files) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      text :opaque_id, null: false, unique: true
      text :filename, null: false
      text :sha256, null: false
      text :content_type, null: false
      int :content_length, null: false
      foreign_key :created_by_id, :members
    end
  end
end
