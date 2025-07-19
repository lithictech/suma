# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:i18n_static_strings) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      foreign_key :text_id,
                  :translated_texts,
                  on_delete: :cascade, # Translated texts are 'owned' by these strings
                  null: true # Must allow to be null for safe upserts
      text :key, null: false
      text :namespace, null: false
      index [:key, :namespace], unique: true
      boolean :deprecated, null: false, default: false
      timestamptz :modified_at, null: false
    end
  end
end
