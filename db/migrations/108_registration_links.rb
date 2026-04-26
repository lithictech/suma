# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:organization_registration_links) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      foreign_key :created_by_id, :members, on_delete: :set_null

      foreign_key :organization_id, :organizations, null: false, index: true, on_delete: :cascade
      foreign_key :intro_id, :translated_texts, null: false

      text :opaque_id, null: false, unique: true
      timestamptz :ical_dtstart
      timestamptz :ical_dtend
      text :ical_rrule, null: false, default: ""

      column :search_content, :text
      column :search_embedding, "vector(384)"
      column :search_hash, :text
      index Sequel.function(:to_tsvector, "english", :search_content),
            name: :organization_registration_links_search_content_tsvector_index,
            type: :gin
    end

    alter_table(:organization_memberships) do
      add_foreign_key :registration_link_id, :organization_registration_links, index: true, on_delete: :set_null
    end
  end
end
