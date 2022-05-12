# frozen_string_literal: true

module Suma::Payment
  # Every customer should have a 'cash' ledger that is used for almost every service
  # (except those that do not have a 'cash' category, which is rare but possible,
  # if a vendor wants to be paid only in scrip or something else).
  def self.ensure_cash_ledger(customer)
    customer.payment_account ||= Suma::Payment::Account.create(customer:)
    cash_category = Suma::Vendor::ServiceCategory.find_or_create(name: "Cash")
    ledger = customer.payment_account.ledgers.find { |led| led.vendor_service_categories.include?(cash_category) }
    return ledger if ledger
    ledger = customer.payment_account.add_ledger({currency: Suma.default_currency})
    ledger.add_vendor_service_category(cash_category)
    return ledger
  end
end

require "suma/payment/errors"
