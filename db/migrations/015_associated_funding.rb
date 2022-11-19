# frozen_string_literal: true

Sequel.migration do
  change do
    create_join_table(
      {charge_id: :charges, funding_transaction_id: :payment_funding_transactions},
      name: :charges_associated_funding_transactions,
    )
  end
end
