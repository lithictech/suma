# frozen_string_literal: true

require "sequel/unambiguous_constraint"

Sequel.migration do
  up do
    rename_table(:bank_accounts, :payment_bank_accounts)

    create_table(:payment_cards) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      timestamptz :soft_deleted_at

      foreign_key :legal_entity_id, :legal_entities, null: false, on_delete: :restrict

      jsonb :stripe_json, null: false
    end

    create_table(:payment_funding_transaction_stripe_card_strategies) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :originating_card_id, :payment_cards, null: false
      jsonb :charge_json
    end

    alter_table(:payment_funding_transactions) do
      add_column :originating_ip, :inet
      add_foreign_key :stripe_card_strategy_id, :payment_funding_transaction_stripe_card_strategies,
                      null: true, unique: true

      drop_constraint(:unambiguous_strategy)
      add_constraint(
        :unambiguous_strategy,
        Sequel.unambiguous_constraint([:fake_strategy_id, :increase_ach_strategy_id, :stripe_card_strategy_id]),
      )
    end

    alter_table(:members) do
      add_column :stripe_customer_json, :jsonb
    end
  end
  down do
    rename_table(:payment_bank_accounts, :bank_accounts)
    alter_table(:payment_funding_transactions) do
      drop_constraint(:unambiguous_strategy)
      add_constraint(
        :unambiguous_strategy,
        Sequel.unambiguous_constraint([:fake_strategy_id, :increase_ach_strategy_id]),
      )
      drop_column :originating_ip
      drop_column :stripe_card_strategy_id
    end
    alter_table(:members) do
      drop_column :stripe_customer_json
    end
    drop_table(:payment_funding_transaction_stripe_card_strategies)
    drop_table(:payment_cards)
  end
end
