# frozen_string_literal: true

# Adds helper methods for objects that have a +charges+ (order) or +charge+ association (trip).
module Suma::Charge::Has
  private def _allcharges = self.respond_to?(:charges) ? self.charges : [self.charge].compact

  # How much was paid for this order is the sum of all book transactions linked to charges.
  # Note that this includes subsidy AND synchronous charges during checkout.
  def paid_amount = _allcharges.sum(Money.new(0), &:discounted_subtotal)
  alias paid_cost paid_amount

  # How much of the paid amount was synchronously funded during checkout?
  # Note that there is no book transaction associated from the charge (which are all debits)
  # to the funding transaction (which is a credit)- payments work with ledgers, not linking
  # charges to orders, so we keep track of this additional data via associated_funding_transaction.
  def funded_amount
    return _allcharges.map(&:associated_funding_transactions).flatten.sum(Money.new(0), &:amount)
  end
  alias funded_cost funded_amount

  # How much in cash did the user pay for this, either real-time or from a cash ledger credit.
  # Ie, how many of the book transactions for charges came from the cash ledger?
  def cash_paid = self.payment_group_amounts.fetch(:cash)

  # How much did the user send from ledgers that weren't the cash ledger?
  # This does NOT capture off-platform transactions ('self data' in charge line items),
  # so cash_paid + noncash_paid may not equal the paid_cost.
  def noncash_paid = self.payment_group_amounts.fetch(:noncash)

  def payment_group_amounts
    cash_led = self.member.payment_account&.cash_ledger
    cash = Money.new(0)
    noncash = Money.new(0)
    _allcharges.each do |ch|
      ch.line_items.
        filter_map(&:book_transaction).each do |bx|
        if bx.originating_ledger === cash_led
          cash += bx.amount
        else
          noncash += bx.amount
        end
      end
    end
    return {cash:, noncash:}
  end
end
