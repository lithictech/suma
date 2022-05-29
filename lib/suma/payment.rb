# frozen_string_literal: true

require "biz"
require "holidays"

module Suma::Payment
  APPROXIMATE_ACH_SCHEDULE = Biz::Schedule.new do |config|
    config.hours = {
      mon: {"09:00" => "15:00"},
      tue: {"09:00" => "15:00"},
      wed: {"09:00" => "15:00"},
      thu: {"09:00" => "15:00"},
      fri: {"09:00" => "15:00"},
    }
    config.time_zone = "America/New_York"
    config.holidays = Holidays.between(Date.new(2020, 7, 1), 1.year.from_now, :us, :observed).
      map { |h| h[:date] }
  end

  # Every customer should have a 'cash' ledger that is used for almost every service
  # (except those that do not have a 'cash' category, which is rare but possible,
  # if a vendor wants to be paid only in scrip or something else).
  def self.ensure_cash_ledger(customer_or_payment_account)
    payment_account = if customer_or_payment_account.is_a?(Suma::Customer)
                        Suma::Payment::Account.find_or_create_or_find(customer: customer_or_payment_account)
    else
      customer_or_payment_account
   end
    ledger = payment_account.cash_ledger
    return ledger if ledger
    ledger = payment_account.add_ledger({currency: Suma.default_currency})
    cash_category = Suma::Vendor::ServiceCategory.find_or_create(name: "Cash")
    ledger.add_vendor_service_category(cash_category)
    payment_account.associations.delete(:cash_ledger)
    return ledger
  end
end

require "suma/payment/errors"
