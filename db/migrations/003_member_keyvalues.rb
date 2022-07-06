# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:member_key_values) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      foreign_key :member_id, :members, null: false, on_delete: :cascade
      text :key, null: false
      text :value_string, null: true

      index [:key, :member_id], name: :unique_member_key_idx, unique: true
    end
  end
end
