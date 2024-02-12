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

  class UnsupportedMethod < Error; end

  configurable(:payments) do
    setting :autoverify_account_numbers, [], convert: ->(s) { s.split }
    setting :minimum_funding_amount_cents, 500
    setting :supported_methods, ["bank_account", "card"], convert: ->(s) { s.split }
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

  # Certain Suma deployments may only support certain payment instruments-
  # for example, it may be easy to get set up with cards but difficult to
  # start using bank accounts, or perhaps this is an entirely unbanked instance
  # that only uses script. When a payment method is not enabled:
  #
  # - Funding transactions using those instruments is disabled.
  # - Adding those instruments is disabled.
  # - They do not show up in a member's 'usable instruments'.
  # - They do not show in the UI.
  #
  # Removing support for an instrument on an established instance is not
  # considered a 'safe' operation since a disabled instrument
  # may be linked to active checkouts, etc. If this is needed in the future,
  # we need to add better support for it.
  def self.method_supported?(x)
    return self.supported_methods.include?(x.to_s)
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
    payment_account.ensure_cash_ledger
  end
end

require "suma/payment/errors"
