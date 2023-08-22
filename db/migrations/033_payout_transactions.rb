# frozen_string_literal: true

require "sequel/unambiguous_constraint"

Sequel.migration do
  change do
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
  end
end
