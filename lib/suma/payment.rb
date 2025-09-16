# frozen_string_literal: true

require "biz"
require "holidays"
require "mimemagic"

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

  class Institution
    attr_reader :name, :logo_src, :color

    def initialize(name:, logo:, color:)
      @name = name
      @color = color
      @logo_src = self.class.logo_to_src(logo)
    end

    PNG_PREFIX = "iVBORw0KGgo"

    def self.logo_to_src(arg)
      return "" if arg.nil?
      return arg if /^[a-z]{2,10}:/.match?(arg)
      return "data:image/png;base64,#{arg}" if arg.start_with?(PNG_PREFIX)
      begin
        raw = Base64.strict_decode64(arg[...(4 * 10)]) # base64 string length is divisible by 4
      rescue ArgumentError
        return arg
      end
      matched = MimeMagic.by_magic(raw)
      return arg unless matched
      return "data:#{matched};base64,#{arg}"
    end
  end

  configurable(:payments) do
    # Bank accounts with these numbers will be verified automatically.
    setting :autoverify_account_numbers, [], convert: lambda(&:split)

    # The balance on the cash ledger that a customer must have in order to use services.
    # If the ledger cash balance is below this, services are disabled immediately.
    # For example, a value of -20_00 would still allow use of services with a cash balance of -$10
    # (but see +negative_cash_balance_grace_period+ for caveats).
    # See also +Suma::Payment.can_use_services?+.
    setting :minimum_cash_balance_for_services_cents, 0

    # When a member creates a funding transaction to add money to their cash ledger,
    # it must be at least this much. Be careful using too-low amounts,
    # which incur proportionally large fees.
    setting :minimum_funding_amount_cents, 500

    # If the cash ledger balance is negative,
    # and has been for longer than the duration of this grace period,
    # disable access to services. This allows the use of a +minimum_cash_balance_for_services_cents+
    # which is substantial, like -$20 (so members aren't stranded if their payments stop working),
    # while cutting off services if the balance remains negative.
    # See also +Suma::Payment.can_use_services?+.
    setting :negative_cash_balance_grace_period, 18.hours

    # Disable methods if not set up with the relevant partners/processors.
    setting :supported_methods, ["bank_account", "card"], convert: lambda(&:split)
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

  class << self
    def minimum_funding_amount = Money.new(self.minimum_funding_amount_cents)
    def minimum_cash_balance_for_services = Money.new(self.minimum_cash_balance_for_services_cents)

    # Return true if the payment account can use services.
    # Members are prohibited from using services when:
    # - Their cash ledger balance is less than +minimum_cash_balance_for_services+,
    # - Their cash ledger balance has been negative for more than +negative_cash_balance_grace_period+
    #   (this is only relevant when +minimum_cash_balance_for_services+ is negative).
    #
    # Internal note: We don't take in a 'now' because we want to use the Ledger#balance value as a fast path,
    # which is based on associations. If that fails, we need to calculate using database queries.
    def can_use_services?(payment_account, now: Time.now)
      ledger = payment_account.cash_ledger!
      # We're below the minimum, so this is never ok.
      return false if ledger.balance < self.minimum_cash_balance_for_services
      # We've above the minimum, and the minimum is zero or higher, so we are okay and do not need
      # to worry about grace period.
      return true if self.minimum_cash_balance_for_services >= 0
      # The minimum is negative, but our balance is ok, so we don't need to check the grace period.
      return true if ledger.balance >= 0
      # We have a negative balance that is higher than the minimum.
      # So now we need to see if the ledger has been brought out of the red at any point
      # during the grace period (if it has, the grace period would start over).
      balance = 0
      grace_start = now - self.negative_cash_balance_grace_period
      if (first_bx = ledger.combined_book_transactions_raw.last) && (first_bx.fetch(:apply_at) > grace_start)
        # If the first transaction started after the grace period,
        # we know we cannot have been negative for longer than it.
        return true
      end
      has_been_positive_during_grace_period = false
      ledger.combined_book_transactions_raw.reverse_each do |row|
        balance += row.fetch(:amount_cents)
        if row.fetch(:apply_at) > grace_start && balance >= 0
          has_been_positive_during_grace_period = true
          break
        end
      end
      return has_been_positive_during_grace_period
    end
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

  # Return parameter if it's a payment account, or use it to find/create a payment account if it's a member.
  def self.as_account(member_or_payment_account)
    return Suma::Payment::Account.find_or_create_or_find(member: member_or_payment_account) if
      member_or_payment_account.is_a?(Suma::Member)
    return member_or_payment_account
  end

  # Every member should have a 'cash' ledger that is used for almost every service
  # (except those that do not have a 'cash' category, which is rare but possible,
  # if a vendor wants to be paid only in scrip or something else).
  def self.ensure_cash_ledger(member_or_payment_account)
    payment_account = self.as_account(member_or_payment_account)
    payment_account.ensure_cash_ledger
  end
end

require "suma/payment/errors"
