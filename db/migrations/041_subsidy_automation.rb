# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:payment_triggers) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :label, null: false
      tstzrange :active_during, null: false
      numeric :match_multiplier, null: false
      integer :maximum_cumulative_subsidy_cents, null: false
      foreign_key :memo_id, :translated_texts, null: false

      foreign_key :originating_ledger_id, :payment_ledgers, null: false

      text :receiving_ledger_name, null: false
      foreign_key :receiving_ledger_contribution_text_id, :translated_texts, null: false
    end
    create_table(:payment_trigger_executions) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      foreign_key :book_transaction_id, :payment_book_transactions, null: false
      foreign_key :trigger_id, :payment_triggers, null: false
      unique [:trigger_id, :book_transaction_id]
    end
    create_join_table(
      {constraint_id: :eligibility_constraints, trigger_id: :payment_triggers},
      name: :eligibility_payment_trigger_associations,
    )
    alter_table(:commerce_offerings) do
      drop_column :prohibit_charge_at_checkout
    end
    drop_table(:automation_triggers)
  end

  down do
    create_table(:automation_triggers) do
      primary_key :placeholder
    end
    alter_table(:commerce_offerings) do
      add_column :prohibit_charge_at_checkout, :boolean
    end
    drop_table(:eligibility_payment_trigger_associations)
    drop_table(:payment_trigger_executions)
    drop_table(:payment_triggers)
  end
end
