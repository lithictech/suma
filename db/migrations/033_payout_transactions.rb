# frozen_string_literal: true

require "sequel/unambiguous_constraint"

Sequel.migration do
  up do
    create_table(:payment_payout_transaction_stripe_charge_refund_strategies) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :stripe_charge_id, null: false
      jsonb :refund_json
    end

    create_table(:payment_payout_transactions) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :status, null: false
      int :amount_cents, null: false
      text :amount_currency, null: false
      constraint(:amount_positive, Sequel.lit("amount_cents > 0"))

      foreign_key :memo_id, :translated_texts, null: false
      foreign_key :platform_ledger_id, :payment_ledgers, null: false, index: true, on_delete: :restrict
      foreign_key :originating_payment_account_id, :payment_accounts, null: false, index: true, on_delete: :restrict
      foreign_key :originated_book_transaction_id, :payment_book_transactions,
                  null: true, unique: true, on_delete: :restrict

      foreign_key :fake_strategy_id, :payment_fake_strategies,
                  null: true, unique: true
      foreign_key :stripe_charge_refund_strategy_id, :payment_payout_transaction_stripe_charge_refund_strategies,
                  null: true, unique: true
      constraint(
        :unambiguous_strategy,
        Sequel.unambiguous_constraint([:fake_strategy_id, :stripe_charge_refund_strategy_id]),
      )
    end

    create_table(:payment_payout_transaction_audit_logs) do
      primary_key :id
      timestamptz :at, null: false

      text :event, null: false
      text :to_state, null: false
      text :from_state, null: false
      text :reason, null: false, default: ""
      jsonb :messages, default: "[]"

      foreign_key :payout_transaction_id, :payment_payout_transactions, null: false
      foreign_key :actor_id, :members, on_delete: :set_null
    end

    if ENV["RACK_ENV"] == "test"
      run <<~SQL
        CREATE TABLE stripe_refund_v1_fixture (
          pk bigserial PRIMARY KEY,
          stripe_id text UNIQUE NOT NULL,
          amount integer,
          balance_transaction text,
          charge text,
          created timestamptz,
          payment_intent text,
          receipt_number text,
          source_transfer_reversal text,
          status text,
          transfer_reversal text,
          updated timestamptz,
          data jsonb NOT NULL
        );
        CREATE INDEX IF NOT EXISTS svi_fixture_amount_idx ON stripe_refund_v1_fixture (amount);
        CREATE INDEX IF NOT EXISTS svi_fixture_balance_transaction_idx ON stripe_refund_v1_fixture (balance_transaction);
        CREATE INDEX IF NOT EXISTS svi_fixture_charge_idx ON stripe_refund_v1_fixture (charge);
        CREATE INDEX IF NOT EXISTS svi_fixture_created_idx ON stripe_refund_v1_fixture (created);
        CREATE INDEX IF NOT EXISTS svi_fixture_payment_intent_idx ON stripe_refund_v1_fixture (payment_intent);
        CREATE INDEX IF NOT EXISTS svi_fixture_receipt_number_idx ON stripe_refund_v1_fixture (receipt_number);
        CREATE INDEX IF NOT EXISTS svi_fixture_source_transfer_reversal_idx ON stripe_refund_v1_fixture (source_transfer_reversal);
        CREATE INDEX IF NOT EXISTS svi_fixture_transfer_reversal_idx ON stripe_refund_v1_fixture (transfer_reversal);
        CREATE INDEX IF NOT EXISTS svi_fixture_updated_idx ON stripe_refund_v1_fixture (updated);
      SQL
    end
  end

  down do
    run("DROP TABLE stripe_refund_v1_fixture") if ENV["RACK_ENV"] == "test"
    drop_table(:payment_payout_transaction_audit_logs)
    drop_table(:payment_payout_transactions)
    drop_table(:payment_payout_transaction_stripe_charge_refund_strategies)
  end
end
