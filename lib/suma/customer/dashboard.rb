# frozen_string_literal: true

require "suma/customer"
require "suma/payment/ledgers_view"

class Suma::Member::Dashboard
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
    return Suma::Payment::LedgersView.new(pa.ledgers).recent_lines
  end
end
