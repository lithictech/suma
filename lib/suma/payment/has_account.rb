# frozen_string_literal: true

require "suma/payment"

module Suma::Payment::HasAccount
  def payment_account!
    pa = self.payment_account
    return pa if pa
    raise Suma::InvalidPrecondition,
          "#{self.inspect} does not have a payment_account. " \
          "Use 'ensure_cash_ledger' or something similar to make sure it exists."
  end
end
