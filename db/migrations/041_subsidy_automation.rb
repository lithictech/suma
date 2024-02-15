# frozen_string_literal: true

Sequel.migration do
  change do
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
    create_join_table(
      {constraint_id: :eligibility_constraints, trigger_id: :payment_triggers},
      name: :eligibility_payment_trigger_associations,
    )
    alter_table(:commerce_offerings) do
      rename_column :prohibit_charge_at_checkout, :prohibit_charge_at_checkout_legacy
    end
  end
end
