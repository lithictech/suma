# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:i18n_static_strings) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      foreign_key :translated_text_id, :translated_texts # Must allow to be null for safe upserts
      text :key, null: false, unique: true
      boolean :deprecated, null: false, default: false
      timestamptz :modified_at, null: false
    end
  end
end
