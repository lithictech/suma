# frozen_string_literal: true

require "sequel/null_or_present_constraint"

Sequel.migration do
  up do
    create_table(:payment_funding_transaction_off_platform_strategies) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :created_by_id, :members, null: true, on_cascade: :set_null
      text :created_by_name, null: false
      text :note, null: false
      text :check_or_transaction_number, index: true
      constraint :null_or_present_number, Sequel.null_or_present_constraint(:check_or_transaction_number)
    end

    create_table(:payment_payout_transaction_off_platform_strategies) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :created_by_id, :members, null: true, on_cascade: :set_null
      text :created_by_name, null: false
      text :note, null: false
      text :check_or_transaction_number, index: true
      constraint :null_or_present_number, Sequel.null_or_present_constraint(:check_or_transaction_number)
    end

    alter_table(:payment_funding_transactions) do
      add_foreign_key :off_platform_strategy_id,
                      :payment_funding_transaction_off_platform_strategies,
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
                      :payment_payout_transaction_off_platform_strategies,
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
    drop_table(:payment_funding_transaction_off_platform_strategies)
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
    drop_table(:payment_payout_transaction_off_platform_strategies)
  end
end
