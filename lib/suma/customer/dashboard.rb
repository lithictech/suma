# frozen_string_literal: true

require "suma/customer"

class Suma::Customer::Dashboard
  def initialize(customer)
    @customer = customer
  end

  def payment_account_balance
    pa = @customer.payment_account
    return Money.new(0) if pa.nil?
    return pa.total_balance
  end

  def lifetime_savings
    return @customer.charges.sum(Money.new(0), &:discount_amount)
  end

  def ledger_lines
    pa = @customer.payment_account
    return [] if pa.nil?
    lines = pa.ledgers.map(&:received_book_transactions).
      flatten.
      map { |bt| LedgerLine.new(at: bt.created_at, amount: bt.amount, memo: bt.memo) }
    lines.concat(
      pa.ledgers.map(&:originated_book_transactions).
      flatten.
      map { |bt| LedgerLine.new(at: bt.created_at, amount: -1 * bt.amount, memo: bt.memo) },
    )
    lines.sort_by!(&:at)
    lines.reverse!
    return lines
  end

  class LedgerLine < Suma::TypedStruct
    attr_reader :at, :amount, :memo
  end
end
