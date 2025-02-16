# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:external_credentials) do
      primary_key :id
      text :service, null: false, unique: true
      timestamptz :expires_at, null: true
      text :data, null: false
    end
  end
end
