# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:member_referral) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)

      text :channel, null: false
      text :event_name, null: false, default: ""

      foreign_key :member_id, :members, null: false, on_delete: :cascade, index: true
    end
  end
end
