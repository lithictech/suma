# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:url_shortener) do
      column :short_id, :text, unique: true, null: false
      column :url, :text, null: false
      column :inserted_at, :timestamptz, null: false, default: Sequel.function(:now)
    end
  end

  down do
    drop_table :url_shortener
  end
end
