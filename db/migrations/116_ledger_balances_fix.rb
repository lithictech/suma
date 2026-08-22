# frozen_string_literal: true

def from(x) = Suma::Member.db[x]
Sequel.migration do
  up do
    drop_view :payment_ledger_balances
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
        all: true,
      )

    ledger_balances = from(directional_book_transactions).
      select(
        Sequel[:ledger_id],
        Sequel.function(:sum, :cents).as(:balance_cents),
        Sequel.function(:max, :apply_at).as(:latest_transaction_at),
      ).group_by(:ledger_id)

    create_view :payment_ledger_balances,
                from(:payment_ledgers).
                  select(
                    Sequel[:payment_ledgers][:id].as(:ledger_id),
                    Sequel[:payment_ledgers][:name].as(:ledger_name),
                    Sequel[:payment_ledgers][:currency].as(:balance_currency),
                    Sequel.function(:coalesce, :balance_cents, 0).as(:balance_cents),
                    :latest_transaction_at,
                  ).
                  left_join(ledger_balances, ledger_id: :id)
  end

  down do
    drop_view :payment_ledger_balances
    # BUGGY query from migration 099
    directional_book_transactions = from(:payment_book_transactions).
      select(
        Sequel[:originating_ledger_id].as(:ledger_id),
        (Sequel[:amount_cents] * -1).as(:cents),
        :apply_at,
      ).union(
        from(:payment_book_transactions).
          select(
            Sequel[:receiving_ledger_id].as(:ledger_id),
            Sequel[:amount_cents].as(:cents),
            :apply_at,
          ),
      ).union(
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
end
