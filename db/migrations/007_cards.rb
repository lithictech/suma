# frozen_string_literal: true

require "sequel/unambiguous_constraint"

Sequel.migration do
  change do
    rename_table(:bank_accounts, :payment_bank_accounts)

    create_table(:payment_cards) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      timestamptz :soft_deleted_at

      foreign_key :legal_entity_id, :legal_entities, null: false, on_delete: :restrict

      jsonb :helcim_json, null: false
    end

    create_table(:payment_funding_transaction_helcim_card_strategies) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :originating_card_id, :payment_cards, null: false
      jsonb :preauth_json, null: false, default: "{}"
      jsonb :capture_json, null: false, default: "{}"
    end

    alter_table(:payment_funding_transactions) do
      add_column :originating_ip, :inet
      add_foreign_key :helcim_card_strategy_id, :payment_funding_transaction_helcim_card_strategies,
                      null: true, unique: true
      drop_constraint(:unambiguous_strategy)
      add_constraint(
        :unambiguous_strategy,
        Sequel.unambiguous_constraint([:fake_strategy_id, :increase_ach_strategy_id, :helcim_card_strategy_id]),
      )
    end
  end
end
