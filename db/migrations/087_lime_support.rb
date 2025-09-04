# frozen_string_literal: true

require "sequel/unambiguous_constraint"

Sequel.migration do
  search_tables = [
    :payment_bank_accounts,
    :payment_cards,
  ]
  up do
    alter_table(:commerce_checkouts) do
      drop_column :save_payment_instrument
    end
    create_table(:program_enrollment_exclusions) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      foreign_key :created_by_id, :members, on_delete: :set_null

      foreign_key :program_id, :programs, null: false, on_delete: :cascade, index: true
      foreign_key :member_id, :members, on_delete: :cascade, index: true
      foreign_key :role_id, :roles, on_delete: :cascade, index: true
      unique [:program_id, :member_id]
      unique [:program_id, :role_id]
      constraint(
        :one_enrollee_set,
        Sequel.unambiguous_constraint([:member_id, :role_id]),
      )
    end
    search_tables.each do |tbl|
      alter_table(tbl) do
        add_column :search_content, :text
        add_column :search_embedding, "vector(384)"
        add_column :search_hash, :text
        add_index Sequel.function(:to_tsvector, "english", :search_content),
                  name: :"#{tbl}_search_content_tsvector_index",
                  type: :gin
      end
    end

    common_columns = [:id, :soft_deleted_at, :search_content, :search_embedding, :search_hash]
    create_view :payment_instruments,
                from(:payment_bank_accounts).
                  select(*common_columns, Sequel.as("bank_account", :type)).
                  union(
                    from(:payment_cards).select(*common_columns, Sequel.as("card", :type)),
                  )
  end
  down do
    alter_table(:commerce_checkouts) do
      add_column :save_payment_instrument, :boolean, default: false
    end
    drop_table(:program_enrollment_exclusions)
    drop_view(:payment_instruments)
    search_tables.each do |tbl|
      alter_table(tbl) do
        drop_column :search_content
        drop_column :search_embedding
        drop_column :search_hash
      end
    end
  end
end
