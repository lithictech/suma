# frozen_string_literal: true

require "sequel/null_or_present_constraint"
require "sequel/unambiguous_constraint"

Sequel.migration do
  up do
    alter_table(:payment_funding_transaction_audit_logs) do
      drop_foreign_key [:funding_transaction_id]
      add_foreign_key [:funding_transaction_id], :payment_funding_transactions, null: false, on_delete: :cascade
    end
    alter_table(:payment_payout_transaction_audit_logs) do
      drop_foreign_key [:payout_transaction_id]
      add_foreign_key [:payout_transaction_id], :payment_payout_transactions, null: false, on_delete: :cascade
    end
    create_table(:payment_off_platform_strategies) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :created_by_id, :members, null: true, on_cascade: :set_null
      text :note, null: false
      text :check_or_transaction_number, index: true
      constraint :null_or_present_number, Sequel.null_or_present_constraint(:check_or_transaction_number)
      timestamptz :transacted_at, null: false
      foreign_key :vendor_id, :vendors
      foreign_key :organization_id, :organizations
    end

    alter_table(:payment_funding_transactions) do
      add_foreign_key :off_platform_strategy_id,
                      :payment_off_platform_strategies,
                      null: true,
                      unique: true

      drop_constraint(:unambiguous_strategy)
      add_constraint(
        :unambiguous_strategy,
        Sequel.unambiguous_constraint(
          [
            :fake_strategy_id,
            :increase_ach_strategy_id,
            :stripe_card_strategy_id,
            :off_platform_strategy_id,
          ],
        ),
      )
    end

    alter_table(:payment_payout_transactions) do
      add_foreign_key :off_platform_strategy_id,
                      :payment_off_platform_strategies,
                      null: true,
                      unique: true

      drop_constraint(:unambiguous_strategy)
      add_constraint(
        :unambiguous_strategy,
        Sequel.unambiguous_constraint(
          [
            :fake_strategy_id,
            :stripe_charge_refund_strategy_id,
            :off_platform_strategy_id,
          ],
        ),
      )
    end
  end

  down do
    from(:payment_funding_transactions).exclude(off_platform_strategy_id: nil).delete
    from(:payment_payout_transactions).exclude(off_platform_strategy_id: nil).delete
    alter_table(:payment_funding_transactions) do
      drop_constraint(:unambiguous_strategy)
      add_constraint(
        :unambiguous_strategy,
        Sequel.unambiguous_constraint(
          [
            :fake_strategy_id,
            :increase_ach_strategy_id,
            :stripe_card_strategy_id,
          ],
        ),
      )
      drop_column :off_platform_strategy_id
    end
    alter_table(:payment_payout_transactions) do
      drop_constraint(:unambiguous_strategy)
      add_constraint(
        :unambiguous_strategy,
        Sequel.unambiguous_constraint(
          [
            :fake_strategy_id,
            :stripe_charge_refund_strategy_id,
          ],
        ),
      )
      drop_column :off_platform_strategy_id
    end
    drop_table(:payment_off_platform_strategies, cascade: true)
  end
end
