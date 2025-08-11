# frozen_string_literal: true

class Suma::Payment::PlatformStatus
  # The total amount and number of transactions we've received that move money onto the platform
  # (which have not been refunded).
  attr_accessor :funding, :funding_count
  # The total amount and number of transactions we've paid out (which aren't refunds).
  attr_accessor :payouts, :payout_count
  # The total amount and number of refund transactions.
  attr_accessor :refunds, :refund_count
  # The pending balance on platform ledgers. A positive value means users are carrying a balance.
  attr_accessor :member_liabilities
  # Funding minus payouts. This is 'potential profit'. Member liabilities reduce assets,
  # but not necessarily by their entire amount (since the actual amount will depend on vendor invoicing).
  attr_accessor :assets
  # Ledgers belonging to the platform account.
  attr_accessor :platform_ledgers
  # Unbalanced ledgers. These do not belong to the platform account,
  # since unbalanced member ledgers always mean unbalanced platform ledgers.
  attr_accessor :unbalanced_ledgers

  attr_accessor :off_platform_funding_transactions, :off_platform_payout_transactions

  def calculate
    self.platform_ledgers = Suma::Payment::Account.lookup_platform_account.ledgers.sort_by(&:name)
    funding_ds = Suma::Payment::FundingTransaction.dataset
    payout_ds = Suma::Payment::PayoutTransaction.dataset
    self.refunds, self.refund_count = sumcnt(payout_ds.exclude(refunded_funding_transaction_id: nil))
    self.payouts, self.payout_count = sumcnt(payout_ds.where(refunded_funding_transaction_id: nil))
    self.funding, self.funding_count = sumcnt(funding_ds)
    self.funding -= self.refunds
    self.funding_count -= self.refund_count
    self.member_liabilities = self.platform_ledgers.sum(&:balance) * -1
    self.assets = self.funding - self.payouts
    self.unbalanced_ledgers = self.find_unbalanced_ledgers_ds.all
    self.off_platform_funding_transactions = offplatform_ds(funding_ds).all
    self.off_platform_payout_transactions = offplatform_ds(payout_ds).all
    return self
  end

  private def sumcnt(ds)
    row = ds.select { [sum(amount_cents).as(cents), count(1).as(count)] }.naked.first
    cents = row.fetch(:cents) || 0
    count = row.fetch(:count)
    return Money.new(cents, Suma.default_currency), count
  end

  private def offplatform_ds(ds)
    ds = ds.exclude(off_platform_strategy_id: nil)
    ds = ds.association_join(:off_platform_strategy)
    ds = ds.order(Sequel.desc(:transacted_at), :off_platform_strategy_id)
    ds = ds.select(Sequel[ds.model.table_name][Sequel.lit("*")])
    return ds
  end

  private def db = @db ||= Suma::Payment::Account.db

  # Return all ledgers that do not have a zero balance.
  # We can do this for all ledgers by aggregating so there is a row for each ledger
  # of all the book transactions they received (assets) and a row for each ledger
  # of all the book transactions they originated (liabilities);
  # then group and sum from this union, and if the total isn't 0, it's unbalanced.
  private def find_unbalanced_ledgers_ds
    combined = Suma::Payment::BookTransaction.
      select { [receiving_ledger_id.as(ledger_id), amount_cents.as(amount)] }.
      union(
        Suma::Payment::BookTransaction.
          select { [originating_ledger_id.as(ledger_id), (amount_cents * -1).as(amount)] },
        all: true,
        from_self: false,
      )
    summed = db.from(combined).
      group(:ledger_id).
      select { [ledger_id, sum(amount).as(total)] }
    unbalanced_ids = db.
      from(summed).
      exclude(total: 0).
      exclude(ledger_id: self.platform_ledgers.map(&:id)).
      select_map(:ledger_id)
    return Suma::Payment::Ledger.order(:account_id, :name, :id).where(id: unbalanced_ids)
  end
end
