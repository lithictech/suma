# frozen_string_literal: true

def from(x) = Suma::Member.db[x]
Sequel.migration do
  up do
    directional_book_transactions = from(:payment_book_transactions).
      # Select all book transaction rows as negative,
      # coming from their originating ledger.
      select(
        Sequel[:originating_ledger_id].as(:ledger_id),
        (Sequel[:amount_cents] * -1).as(:cents),
        :apply_at,
      ).union(
        # Add all book transaction rows as positive,
        # going to their receiving ledger.
        from(:payment_book_transactions).
          select(
            Sequel[:receiving_ledger_id].as(:ledger_id),
            Sequel[:amount_cents].as(:cents),
            :apply_at,
          ),
      ).union(
        # Ensure there is a $0 transaction for every ledger,
        # so those without book transactions get a $0 balance row.
        from(:payment_ledgers).
          select(
            Sequel[:id].as(:ledger_id),
            Sequel[0].as(:cents),
            Sequel[nil].as(:apply_at),
          ),
      ).join(
        from(:payment_ledgers).select(:id, :currency, :name),
        {id: :ledger_id},
      )

    create_view :payment_ledger_balances,
                from(directional_book_transactions).
                  select(
                    Sequel[:ledger_id],
                    Sequel.function(:max, :name).as(:ledger_name),
                    Sequel.function(:sum, :cents).as(:balance_cents),
                    Sequel.function(:max, :currency).as(:balance_currency),
                    Sequel.function(:max, :apply_at).as(:latest_transaction_at),
                  ).group_by(:ledger_id)
  end

  down do
    drop_view :payment_ledger_balances
  end
end
