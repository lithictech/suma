# frozen_string_literal: true

require "biz"
require "holidays"

module Suma::Payment
  include Appydays::Configurable

  class Error < StandardError; end

  class Invalid < Error
    attr_reader :reasons

    def initialize(msg=nil, reasons: [])
      super(msg)
      @reasons = reasons
    end
  end

  configurable(:payments) do
    setting :autoverify_account_numbers, [], convert: ->(s) { s.split }
    setting :minimum_funding_amount_cents, 500
  end

  APPROXIMATE_ACH_SCHEDULE = Biz::Schedule.new do |config|
    config.hours = {
      mon: {"09:00" => "15:00"},
      tue: {"09:00" => "15:00"},
      wed: {"09:00" => "15:00"},
      thu: {"09:00" => "15:00"},
      fri: {"09:00" => "15:00"},
    }
    config.time_zone = "America/New_York"
    config.holidays = Holidays.between(Date.new(2022, 7, 1), 1.year.from_now, :us, :observed).
      map { |h| h[:date] }
  end

  # Every member should have a 'cash' ledger that is used for almost every service
  # (except those that do not have a 'cash' category, which is rare but possible,
  # if a vendor wants to be paid only in scrip or something else).
  def self.ensure_cash_ledger(member_or_payment_account)
    payment_account = if member_or_payment_account.is_a?(Suma::Member)
                        Suma::Payment::Account.find_or_create_or_find(member: member_or_payment_account)
    else
      member_or_payment_account
   end
    ledger = payment_account.cash_ledger
    return ledger if ledger
    ledger = payment_account.add_ledger({currency: Suma.default_currency, name: "Cash"})
    ledger.usage_text.update(en: "Account Balance", es: "Saldo de la cuenta")
    ledger.add_vendor_service_category(Suma::Vendor::ServiceCategory.cash)
    payment_account.associations.delete(:cash_ledger)
    return ledger
  end
end

require "suma/payment/errors"
