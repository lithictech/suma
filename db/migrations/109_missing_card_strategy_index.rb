# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:payment_funding_transaction_stripe_card_strategies) do
      add_index :originating_card_id
    end
  end
end
