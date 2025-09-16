# frozen_string_literal: true

require "suma/member"
require "suma/payment/ledgers_view"

class Suma::Member::Dashboard
  def initialize(member, at:)
    @member = member
    @at = at
  end

  def cash_balance
    # The dashboard is the first thing people see after signing up,
    # and it's possible workers are slow. This would cause an error.
    # So make sure they have a ledger at this point.
    # We don't want to create the ledger for every member,
    # since it would be an issue for tests and all code that never
    # has to worry about a ledger.
    return @cash_balance ||= begin
      Suma::Payment.ensure_cash_ledger(@member)
      @member.payment_account!.cash_ledger!.balance
    end
  end

  def program_enrollments
    # Similar to the cash ledger, make sure every member gets a member role by default.
    return @program_enrollments ||= begin
      Suma::Role.cache.member.ensure!(@member)
      @member.combined_program_enrollments_dataset.active(as_of: @at).
          all.sort_by { |pe| pe.program.ordinal }
    end
  end

  # We only want to prompt for expiring instruments
  def expiring_instruments?
    return @expiring_instruments unless @expiring_instruments.nil?
    return @expiring_instruments ||= Suma::FeatureFlags.expiring_cards.check(@member, false) do
      ds = Suma::Member.for_alerting_about_expiring_payment_instruments(@at).where(id: @member.id)
      !ds.empty?
    end
  end

  def valid_instruments?
    return @valid_instruments unless @valid_instruments.nil?
    return @valid_instruments ||= @member.public_payment_instruments.any?(&:usable_for_funding?)
  end

  # Figure out what alerts to show the user (negative balance, expiring cards).
  # If there are conflicting situations (show one thing and not another),
  # handle those conflicts here.
  # - If they have a negative cash balance, but no, or only expired, instruments, link them to the /funding page.
  # - If they have a negative cash balance, but have a valid instrument, tell them we'll try recharging them.
  # - If they have expiring instruments, but no negative cash balance, link them to /funding.
  def alerts
    r = []
    if cash_balance.negative? && !valid_instruments?
      r << Alert.new("dashboard.negative_cash_balance_no_instrument", "danger")
    elsif cash_balance.negative?
      r << Alert.new("dashboard.negative_cash_balance", "danger")
    elsif expiring_instruments?
      r << Alert.new("dashboard.expiring_instruments", "warning")
    end
    return r
  end

  Alert = Struct.new(:localization_key, :variant, :localization_params)
end
